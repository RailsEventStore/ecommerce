const { environment } = require('@rails/webpacker')
const elm =  require('./loaders/elm')

environment.loaders.append('elm', elm)
module.exports = environment
