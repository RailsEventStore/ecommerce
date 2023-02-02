"use strict";(self.webpackChunk_N_E=self.webpackChunk_N_E||[]).push([[636],{6010:function(e,n,t){t.d(n,{Z:function(){return L}});var a=t(85034),i=t(31373),o=t(46131),r=t(24246),l=t(27378),d=t(79894),c=t.n(d),u=t(48330),s=t(70169),m=t(23892),p=t.n(m),v=t(18962),h=t(8366);var f=function(e){var n=e.type,t=e.label,a="event"===n?h.Z:v.Z;return(0,r.jsxs)("div",{children:[(0,r.jsx)(a,{className:"h-3 w-3 text-gray-700 inline-block mr-1 -mt-0.5"}),(0,r.jsx)("span",{className:"text-gray-700",children:t})]})},b=p()().publicRuntimeConfig,g=(void 0===b?{}:b).basePath,x=void 0===g?"":g,y=function(e){return 8*e.length>150?8*e.length:150},w=function(e){var n=e.id,t=e.target,a=e.source,i=e.label,o=e.isAnimated,r=void 0===o||o;return{id:n,target:t,source:a,type:"smoothstep",arrowHeadType:u.f8.ArrowClosed,animated:r,label:i,labelBgPadding:[8,4],labelBgBorderRadius:4,labelStyle:{fontSize:"6px"},labelBgStyle:{fill:"white",color:"#fff",fillOpacity:.5}}},Z=function(e){var n=e.name,t=e.label,a=e.type,i=e.maxWidth,o=e.renderInColumn,r=e.domain,l=y(t),d=function(e,n,t){return"".concat(x,"/").concat(t?"domains/".concat(t,"/"):"").concat(n,"/").concat(e)}(n,"service"===a?"services":"events",r);return{label:t,link:d,width:l,maxWidth:i,renderInColumn:o}},_=function(e){var n=e.type,t=e.label;return e.includeIcon?(0,r.jsx)(f,{type:n,label:t}):t},C=function(e){var n,t,i=e.name,r=e.domain,l=e.consumers,d=void 0===l?[]:l,c=e.producers,u=void 0===c?[]:c,s=arguments.length>1&&void 0!==arguments[1]?arguments[1]:"#2563eb",m=!(arguments.length>2&&void 0!==arguments[2])||arguments[2],p=arguments.length>3&&void 0!==arguments[3]&&arguments[3],v=arguments.length>4&&void 0!==arguments[4]&&arguments[4],h={x:0,y:0},f="#818cf8",b="#75d7b6",g={fontSize:v?"8px":"auto"},x=u.map((function(e){return y(e.name)})),C=(n=Math).max.apply(n,(0,o.Z)(x)),I=d.map((function(e){return y(e.name)})),j=(t=Math).max.apply(t,(0,o.Z)(I)),k="ev-".concat(i.replace(/ /g,"_")),N=y(i),W=u.map((function(e){return{label:e.name,id:"pr-".concat(e.name.replace(/ /g,"_")),domain:e.domain}})),A=d.map((function(e){return{label:e.name,id:"co-".concat(e.name.replace(/ /g,"_")),domain:e.domain}})),L=W.map((function(e){var n=e.label,t=e.id,i=e.domain,o=y(n),r=C-o,l=0!==r?o-r:C,d=_({type:"service",label:n,includeIcon:v});return{id:t,data:Z({name:n,label:d,type:"service",maxWidth:l,renderInColumn:1,domain:i}),style:(0,a.Z)({border:"2px solid ".concat(b),width:o},g),type:"input",position:h}})),S=A.map((function(e){var n=e.id,t=e.label,i=e.domain,o=y(t),r=_({type:"service",label:t,includeIcon:v});return{id:n,data:Z({name:t,label:r,type:"service",maxWidth:j,renderInColumn:3,domain:i}),style:(0,a.Z)({border:"2px solid ".concat(f),width:o},g),type:"output",position:h}})),B={id:k,data:Z({name:i,label:_({type:"event",label:i,includeIcon:v}),type:"event",maxWidth:N,renderInColumn:2,domain:r}),style:(0,a.Z)({border:"2px solid ".concat(s),width:N},g),position:h},E=W.map((function(e){var n=e.id,t=e.label;return w({id:"epe-".concat(t.replace(/ /g,"_"),"-").concat(k),source:n,target:k,isAnimated:m,label:p?"publishes":""})})),M=A.map((function(e){var n=e.id,t=e.label;return w({id:"ece-".concat(t.replace(/ /g,"_"),"-").concat(k),target:n,source:k,isAnimated:m,label:p?"subscribed by":""})})),z=(0,o.Z)(L).concat([B],(0,o.Z)(S),(0,o.Z)(E),(0,o.Z)(M));return z},I=function(e){var n,t,i=e.publishes,r=e.subscribes,l=e.name,d=e.domain,c=arguments.length>1&&void 0!==arguments[1]?arguments[1]:"#2563eb",u=!(arguments.length>2&&void 0!==arguments[2])||arguments[2],m=arguments.length>3&&void 0!==arguments[3]&&arguments[3],p=arguments.length>4&&void 0!==arguments[4]&&arguments[4],v={x:0,y:0},h="#818cf8",f="#75d7b6",b={fontSize:p?"8px":"auto"},g=i.map((function(e){return y(e.name)})),x=(n=Math).max.apply(n,(0,o.Z)(g)),C=r.map((function(e){return y(e.name)})),I=(t=Math).max.apply(t,(0,o.Z)(C)),j="ser-".concat(l.replace(/ /g,"_")),k=i.map((function(e){var n=y(e.name),t=_({type:"event",label:e.name,includeIcon:p});return{id:"pub-".concat(e.name.replace(/ /g,"_")),data:Z({name:e.name,label:t,type:"event",maxWidth:x,renderInColumn:3,domain:e.domain}),style:(0,a.Z)({border:"2px solid ".concat(h),width:n},b),type:"output",position:v}})),N=r.map((function(e){var n=y(e.name),t=I-n,i=0!==t?n-t:I,o=_({type:"event",label:e.name,includeIcon:p});return{id:"sub-".concat(e.name.replace(/ /g,"_")),data:Z((0,s.Z)((0,a.Z)({name:e.name,label:o,type:"event",maxWidth:i},b),{renderInColumn:1,domain:e.domain})),style:(0,a.Z)({border:"2px solid ".concat(f),width:n},b),type:"input",position:v}})),W={id:j,data:Z({name:l,label:_({type:"service",label:l,includeIcon:p}),type:"service",maxWidth:y(l),renderInColumn:2,domain:d}),style:(0,a.Z)({border:"2px solid ".concat(c),width:y(l)},b),position:v},A=i.map((function(e){return w({id:"ecp-".concat(e.name.replace(/ /g,"_")),source:j,target:"pub-".concat(e.name.replace(/ /g,"_")),isAnimated:u,label:m?"publishes":""})})),L=r.map((function(e){return w({id:"esc-".concat(e.name.replace(/ /g,"_")),target:j,source:"sub-".concat(e.name.replace(/ /g,"_")),isAnimated:u,label:m?"subscribed by":""})})),S=(0,o.Z)(N).concat([W],(0,o.Z)(k),(0,o.Z)(A),(0,o.Z)(L));return S},j=t(24259),k=t.n(j),N=150;function W(e,n){var t=new(k().graphlib.Graph);t.setDefaultEdgeLabel((function(){return{}})),t.setGraph({rankdir:"LR",ranksep:96,nodesep:32}),e.forEach((function(e){if((0,u.UG)(e)){var n,a,i,o,r=(null===(n=e.__rf)||void 0===n?void 0:n.width)?null===(a=e.__rf)||void 0===a?void 0:a.width:null===(i=e.data)||void 0===i?void 0:i.width;t.setNode(e.id,{width:r||N,height:(null===(o=e.__rf)||void 0===o?void 0:o.height)||36})}else t.setEdge(e.source,e.target)})),k().layout(t);var a=e.filter((function(e){return e.data})),i=e.filter((function(e){return!e.data})),r=a.sort((function(e,n){return e.data.renderInColumn>n.data.renderInColumn?1:n.data.renderInColumn>e.data.renderInColumn?-1:0}));return(0,o.Z)(r).concat((0,o.Z)(i)).map((function(a){if((0,u.UG)(a)){var i,o=t.node(a.id);a.targetPosition=n?u.Ly.Left:u.Ly.Top,a.sourcePosition=n?u.Ly.Right:u.Ly.Bottom;var r=a.data.renderInColumn>1?75:0,l=null===a||void 0===a||null===(i=a.data)||void 0===i?void 0:i.renderInColumn,d=function(e,n){var t=e.filter((function(e){var t;return(null===e||void 0===e||null===(t=e.data)||void 0===t?void 0:t.renderInColumn)===n}));if(0===t.length)return{};if(1===t.length)return t[0];var a=t.reduce((function(e,n){var t,a,i,o=(null===e||void 0===e||null===(t=e.data)||void 0===t?void 0:t.maxWidth)||(null===e||void 0===e||null===(a=e.data)||void 0===a?void 0:a.width)||N;return((null===n||void 0===n||null===(i=n.data)||void 0===i?void 0:i.maxWidth)||(null===n||void 0===n?void 0:n.data.width)||N)>o?n:e}),t[0]);return a}(e,l-1),c=Object.keys(d).length>0?function(e){var n,t=(null===e||void 0===e||null===(n=e.data)||void 0===n?void 0:n.maxWidth)||e.width||N;return e.position.x+t}(d):0;a.position={x:c+r,y:o.y-o.height/2},a.style.width&&a.style.width<=N&&(a.style.width=void 0)}return a}))}function A(e){var n=e.data,t=e.source,a=e.rootNodeColor,i=e.maxZoom,d=void 0===i?10:i,c=e.isAnimated,s=void 0===c||c,m=e.fitView,p=void 0===m||m,v=e.zoomOnScroll,h=void 0!==v&&v,f=e.isDraggable,b=void 0!==f&&f,g=e.isHorizontal,x=void 0===g||g,y=e.includeBackground,w=void 0!==y&&y,Z=e.includeEdgeLabels,_=void 0!==Z&&Z,j=e.includeNodeIcons,k=e.title,N=e.subtitle,A=(0,l.useCallback)((function(){if("domain"===t||"all"===t){var e=n.events.map((function(e){return C(e,a,s,!0,!0)})),i=n.services.map((function(e){return I(e,a,s,!0,!0)})),r=e.flat().concat(i.flat());return(0,o.Z)(new Map(r.map((function(e){return[e.id,e]}))).values())}return"event"===t?C(n,a,s,_,j):I(n,a,s,_,j)}),[n,_,j,s,a,t]),L=(0,u.Hs)().fitView,S=(0,l.useState)([]),B=S[0],E=S[1];(0,l.useEffect)((function(){var e=W(A(),x);E(e),setTimeout((function(){L()}),1)}),[n,A,x,L]);var M=(0,l.useCallback)((function(e){p&&e.fitView()}),[p]);return(0,r.jsxs)(u.ZP,{elements:B,onLoad:M,onElementClick:function(e,n){return window.open(n.data.link,"_self")},nodesDraggable:b,zoomOnScroll:h,maxZoom:d,children:[k&&(0,r.jsxs)("div",{className:"absolute top-4 right-4 bg-white z-10 text-lg px-4 py-2 space-x-2",children:[(0,r.jsx)("span",{className:" font-bold",children:k}),N&&(0,r.jsxs)(r.Fragment,{children:[(0,r.jsx)("span",{className:"text-gray-200",children:"|"}),(0,r.jsx)("span",{className:"font-light",children:N})]})]}),(0,r.jsx)(u.ZX,{className:"block absolute top-5 react-flow__controls-no-shadow"}),w&&(0,r.jsx)(u.Aq,{color:"#c1c1c1",gap:8})]})}var L=function(e){var n=e.maxHeight,t=e.renderWithBorder,o=void 0===t||t,l=(0,i.Z)(e,["maxHeight","renderWithBorder"]),d=n||function(e){var n=e.source,t=e.data,a=0;return"event"===n&&(a=68*Math.max(t.producerNames.length,t.consumerNames.length)),"service"===n&&(a=68*Math.max(t.publishes.length,t.subscribes.length)),Math.max(300,a)}(l);return(0,r.jsxs)("div",{className:"node-graph w-full h-screen ".concat(o?"border-dashed border-2 border-slate-300":""),style:{height:d},children:[(0,r.jsx)(u.tV,{children:(0,r.jsx)(A,(0,a.Z)({},l))}),(0,r.jsx)(c(),{href:"/visualiser?type=".concat(l.source,"&name=").concat(l.data.name),children:(0,r.jsx)("a",{className:"block text-right underline text-xs mt-4",children:"Open in Visualiser \u2192"})})]})}},41978:function(e,n,t){function a(e){for(var n=0,t=0;t<e.length;t++)n=e.charCodeAt(t)+((n<<5)-n);for(var a="#",i=0;i<3;i++){a+="00".concat((n>>8*i&255).toString(16)).substr(-2)}return a}t.d(n,{Z:function(){return a}})}}]);