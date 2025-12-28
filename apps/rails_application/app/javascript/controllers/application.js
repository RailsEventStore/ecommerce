import { Application } from "@hotwired/stimulus"

const application = Application.start()

application.debug = false
application.handleError = (error, message, detail) => {
    application.logger.error(`%s\n\n%o\n\n%o`, message, error, detail);
};
window.Stimulus   = application

export { application }