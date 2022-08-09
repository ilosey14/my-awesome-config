local logger = require('lib.logger')
logger.log('Starting awesome rc...')

require('config')
require('desktop')
require('utils')

logger.log('...complete')
