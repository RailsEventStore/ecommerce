const { environment } = require('@rails/webpacker')
const elm =  require('./loaders/elm')

environment.loaders.prepend('elm', elm)
module.exports = environment
