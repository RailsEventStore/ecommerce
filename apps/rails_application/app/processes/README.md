# Prototyp deklaratywnych process managerów

`ReleasePaymentOnOrderExpiration` i `ShipmentProcess` korzystają ze wspólnej
definicji joinów oraz czystych funkcji `evolve` i `decide`. Dotychczasowa
konfiguracja aplikacji zachowuje stare zachowanie. Ograniczony deadline'em cykl
życia jest osobnym, jawnie uruchamianym eksperymentem, nie zmianą polityki biznesowej.

## Definicja jest źródłem decyzji i specyfikacji

Fragment `ReleasePaymentOnOrderExpiration::Definition`:

```ruby
JoinDefinition.new(
  [JoinDefinition::Rule.new(
    JoinDefinition.event(Payments::PaymentAuthorized) & JoinDefinition.event(Pricing::OfferExpired),
    :release_payment,
    JoinDefinition::Pattern.new([])
  )],
  { Payments::PaymentReleased => Payments::PaymentAuthorized },
  JoinDefinition.event(Payments::PaymentReleased)
)
```

Argumenty definicji to uporządkowane reguły, unieważnienia faktów i wzorzec
zakończenia. Argumenty reguły to join, akcja oraz wzorzec blokujący akcję.
Pusty wzorzec nie pasuje do żadnej historii. Akcja wskazuje istniejącą metodę
procesu wysyłającą komendę, więc szczegóły domenowe pozostają w procesie.

`&` tworzy koniunkcję, `|` alternatywę. Można je mieszać:

```ruby
(JoinDefinition.event(Fulfillment::OrderRegistered) | JoinDefinition.event(Pricing::OfferExpired)) & JoinDefinition.event(Payments::PaymentAuthorized)
```

Ten ostatni wzorzec jest przykładem składni, nie regułą biznesową aplikacji.
Oba przepisane procesy potrzebują wyłącznie koniunkcji.

Wzorce są normalizowane do alternatywy koniunkcji. `evolve(state, event)`
odtwarza ostatnie zdarzenie każdego typu i stosuje unieważnienia. Nie wysyła
komend. `decide(state)` zwraca nazwę akcji pierwszej pasującej reguły albo pustą
listę. Pierwszeństwo reguł zachowuje dotychczasowe `if/elsif` procesu wysyłki.
Zdarzenia zachowują payload, w tym `store_id`; nie są tylko flagami obecności.

Nie konsumujemy joinów po wydaniu komendy. Blokuje je dopiero odpowiedź domeny.
Zachowuje to również ponowienia komend przed odpowiedzią, obecne w starej
implementacji. `PaymentReleased` usuwa fakt `PaymentAuthorized`, a nie fakt
`OfferExpired`. Ponowna autoryzacja po zwolnieniu płatności nadal może wywołać
`ReleasePayment` w trybie zgodności.

## Timeout jest zdarzeniem, a scheduler jawnym portem

Wariant ograniczony czasowo wymaga dodatniego, skończonego timeoutu w sekundach
oraz schedulera:

```ruby
Processes::ReleasePaymentOnOrderExpiration.new
  .with(event_store: event_store, command_bus: command_bus)
  .with_timeout(90, scheduler)
```

90 sekund to przykład, nie wybrany produkcyjny SLA. Po pierwszym niekońcowym
zdarzeniu adapter zapisuje `JoinDefinition::TimeoutScheduled` na strumieniu
`Processes::ReleasePaymentOnOrderExpiration::Bounded$<order_id>`. Zapis zawiera
`order_id`, `seconds` i `timeout_event_id`. Następnie wywołuje:

```ruby
scheduler.call(timeout_event, process_stream_name, seconds)
```

`timeout_event` jest `JoinDefinition::TimedOut`, z utrwalonym identyfikatorem
zdarzenia, `order_id` oraz nazwą klasy procesu w `data[:process]`.
Scheduler ma po upływie czasu dostarczyć ten event do wskazanej instancji
procesu: najpierw zapisać event globalnie w event store, następnie wywołać
`process.call(event)`. Istniejący adapter RES linkuje go na strumień procesu.
Scheduler nie powinien wcześniej dopisywać go do tego strumienia, bo RES
wykonuje linkowanie sam. Strumień jest adresem routingu, nie dodatkowym
strumieniem agregatu, na którym proces szuka informacji.

Nie wystarczy subskrybować wszystkich instancji do wspólnego typu `TimedOut`:
router musi wybrać klasę procesu oraz `order_id`, zgodnie z adresem strumienia.
`Killed` dostarcza się tą samą drogą. Subskrypcje aplikacji nie zostały zmienione;
testy pokazują scheduler zbierający terminy oraz jawne dostarczenie eventu.

Jeden timer obejmuje cały proces, również obie fazy wysyłki. Nie restartujemy
go po częściowym spełnieniu joinu. Replay nie uruchamia schedulera ani komend.
Odtworzenie nowej instancji i obsługa kolejnego eventu nie planują drugiego
timera, jeżeli intencja już istnieje w historii.

W trybie ograniczonym `evolve(state, event, true)` wyznacza wynik:

| Wynik | Przyczyna |
| --- | --- |
| `Completed` | `PaymentReleased` dla zwolnienia płatności; `ShipmentAuthorized` dla wysyłki |
| `TimedOut` | dostarczenie eventu `JoinDefinition::TimedOut` |
| `Killed` | dostarczenie eventu `JoinDefinition::Killed` |

Każdy wynik jest nieodwracalny. Kolejne eventy, także spóźniony timer, nie
zmieniają stanu ani nie wywołują akcji. Timeout i kill nie wysyłają kompensacji:
nie ustalono jeszcze ich reguł biznesowych. Sam `OfferExpired` nadal pochodzi
z domeny Pricing; timeout procesu go nie zastępuje.

Oddzielne strumienie `::Bounded$` zapobiegają zmianie interpretacji istniejących
instancji. Stare nazwy strumieni i formaty eventów pozostają bez zmian.
Zmienia się odtwarzany obiekt stanu, który nie jest osobno utrwalany, więc
prototyp nie wymaga resetowania demo bazy.

## Specyfikację generuje działający kod

Z katalogu `apps/rails_application`:

```sh
RAILS_ENV=test bin/rails runner '[Processes::ReleasePaymentOnOrderExpiration, Processes::ShipmentProcess].each { |process| puts "## #{process}\n#{process::Definition.specification}\n\n" }'
```

Wynik zawiera reguły Given/When/Then, blokady i trzy zakończenia. Są to warunki
reakcji po zdarzeniu, nie wygenerowane wykonywalne testy. Akcje są nazwami metod
procesu, nie analizą ich ciał. Reguły są uporządkowane; jeżeli pasuje kilka,
wykonuje się pierwsza. Linie zakończeń opisują wyłącznie tryb ograniczony.
`unless ()` oznacza brak blokady.

## Co świadomie pominięto z proponowanej pracy

- Nie ma kompilatora do tablicy przejść ani osobnego Join-Calculus IR. Jest
  mała normalizacja wzorców i interpretacja przez czyste `evolve/decide`.
- Nie ma type-state buildera uniemożliwiającego zdefiniowanie nieograniczonego
  procesu. Tryb zgodności celowo nadal istnieje. Obowiązkowy timeout dotyczy
  wejścia do eksperymentu przez `with_timeout`, nie starej konfiguracji.
- Nie ma dowodu totalności, WCET ani gwarancji zakończenia w czasie rzeczywistym.
  Bez dostarczenia timera proces nie przejdzie do `TimedOut`. Normalizacja
  złożonych wzorców do DNF może zwiększać rozmiar wykładniczo.
- Nie ma trwałego schedulera, outboxa, workerów ani produkcyjnego routingu
  eventów kontrolnych. Awaria między zapisem intencji a wywołaniem schedulera
  może zgubić timer; potrzebne byłoby niezawodne dostarczanie intencji.
- Nie ma gwarancji exactly-once, deduplikacji dostarczeń ani konfluencji wyścigu
  zakończenia z timeoutem. Kolejność utrwalonych eventów rozstrzyga wynik.
  Ponowne dostarczenie tego samego event ID podlega zachowaniu istniejącego RES.
- Nie ma branch/retry, wersjonowania definicji, migracji aktywnych instancji,
  retencji, nadzoru nad procesami ani formalnych dowodów. Nie są potrzebne do
  oceny joinów na tych dwóch synchronicznych procesach.

Ogólne `JoinDefinition` i `JoinProcess` należą do komponentu aplikacji w
ArchSpec, a nie do nowego biznesowego process managera. Oba istniejące procesy
zachowują swoje granice. Nie dodano wyjątków architektonicznych ani wykluczeń
Mutanta.
