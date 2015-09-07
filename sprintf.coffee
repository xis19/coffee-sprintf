###
  sprintf implementation in CoffeeScript

  Copyright (c) 2015, Xiaoge Su
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

  * Neither the name of coffee-sprintf nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

###*
  * Conversion Specifier class
###
class ConversionSpecifier
  ###*
    * Conversion specifier constructor
    * @param {String} [flag]
    * @param {Number} [width]
    * @param {Number} [precision]
    * @param {String} [length]
    * @param {String} [specifier]
    * @param {Boolean} [precisionDefined]
  ###
  constructor: (flag, @width, @precision, @length, @specifier, @precisionDefined) ->
    @flag = flag || ''

  ###*
    * Check if a flag is defined
    * @param {String} [flagChar]
  ###
  hasFlag: (flagChar) ->
    @flag.indexOf(flagChar) != -1


###*
  * String presentation of NaN
  * @type {String}
  * @const
###
NAN = NaN.toString()
###*
  * String presentation of Infinity
  * @type {String}
  * @const
###
INFINITY = Infinity.toString()
###*
  * Flags for conversion specifier
  * @type {String}
  * @const
###
FLAGS = '-+ #0'
###*
  * Conversion specifiers
  * @type {String}
  * @const
###
CONVERSION_SPECIFIERS = 'dioxXfFeEgGcs%'
###*
  * Conversion specifiers for numerical values
  * @type {String}
  * @const
###
NUMERIC_CONVERSION_SPECIFIERS = 'dioxXaAeEfFgG'
###*
  * Conversion specifiers for integer values
  * @type {String}
  * @const
###
INTEGER_CONVERSION_SPECIFIERS = 'dioxX'
###*
  * Regular Expression to capture conversion specifiers
  * @type {RegExp}
  * @const
###
CONVERSION_SPECIFIER_REGEXP = new RegExp(
  "^([#{FLAGS}]*)?(\\d+|\\*)?(\\.(\\d+|\\*)?)?(hh|h|l|ll|j|z|t|L)?([#{CONVERSION_SPECIFIERS}])")

###*
  * Conversion specifiers with implied precision 1
  * @type {String}
  * @const
###
DEFAULT_PRECISION_1_SPECIFIERS = 'dioxX'
###*
  * Conversion specifiers with implied precision 6
  * @type {String}
  * @const
###
DEFAULT_PRECISION_6_SPECIFIERS = 'fFeEgG'
###*
  * Conversion specifiers with implied precision null
  * @type {String}
  * @const
###
DEFAULT_PRECISION_NULL_SPECIFIERS = 'cs%'

###*
  * Conversion specifier for exponential term
  * @type {ConversionSpecifier}
  * @const
###
EXPONENTIAL_TERM_CONVERSION_SPECIFIER = new ConversionSpecifier('+', 0, 2, 'd', true)

###*
  * Get the default precision value for a given conversion specifier
  * @param {String} [specifier] conversion specifier
  * @return {Number, null}
###
getDefaultPrecision = (specifier) ->
  if specifier in DEFAULT_PRECISION_1_SPECIFIERS
    1
  else if specifier in DEFAULT_PRECISION_6_SPECIFIERS
    6
  else if specifier in DEFAULT_PRECISION_NULL_SPECIFIERS
    null
  else
    throw new Error("Unexpected specifier #{specifier}")

###*
  * Get the padding character for a given conversionSpec
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
getPaddingCharacter = (conversionSpec) ->
  if !conversionSpec.hasFlag('0') || conversionSpec.hasFlag('-')
    ' '
  else if conversionSpec.precisionDefined && conversionSpec.specifier in INTEGER_CONVERSION_SPECIFIERS
    ' '
  else
    '0'

###*
  * Convert a float number to string, to a fixed number of decimals
  * @param {Number} [value]
  * @param {Number} [precision]
  * @return {String}
###
toFixedRound = (value, precision) ->
  (+(Math.round(+(value + 'e' + precision)) + 'e' + -precision)).toFixed(precision);

###*
  * Convert a float number to a float value in (-10, 10) and exponential term
  * @param {Number} [value]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {Array}
###
toExponential = (value) ->
  expTerm = 0

  # XXX This is a naive implementation. Need to check for other implementations for better performance.
  while Math.abs(value) > 10
    ++expTerm
    value /= 10
  while 0 < Math.abs(value) < 1
    --expTerm
    value *= 10
  [value, expTerm]

###*
  * Convert a float nmber to a float value in (-16, 16) and exponetial term
  * @param {Number} [value]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {Array}
###
toHexExponential = (value) ->
  expTerm = 0

  # XXX This is a naive implementation. Need to check for other implementations for better performance.
  while Math.abs(value) > 16
    ++expTerm
    value /= 16
  while 0 < Math.abs(value) < 1
    ++expTerm
    value *= 16

  [value, expTerm]

###*
  * Get the prefix sign character base on the value
  * @param {Number} [value]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
getSignPrefix = (value, conversionSpec) ->
  if value < 0
    '-'
  else
    if conversionSpec.hasFlag('+')
      '+'
    else if conversionSpec.hasFlag(' ')
      ' '
    else
      ''

###*
  * For a string, adjust the width by padding using paddingCharacter, also add the sign
  * @param {String} [string]
  * @param {Object} [conversionSpec]
  * @param {String} [sign]
  * @param {String, null} [overridePaddingCharacter]
  * @return {String}
###
adjustSignWidth = (string, conversionSpec, sign = '', overridePaddingCharacter = null) ->
  if !(conversionSpec.width && conversionSpec.width > string.length)
    string = sign + string
  else
    paddingCharacter = overridePaddingCharacter || getPaddingCharacter(conversionSpec)
    spaces = Array(conversionSpec.width - string.length - sign.length + 1).join(paddingCharacter)
    if conversionSpec.hasFlag('-')
      string = sign + string + spaces
    else if paddingCharacter == '0'
      string = sign + spaces + string
    else
      string = spaces + sign + string

  string

###*
  * Format a NaN based on conversionSpec
  * @param {ConversionSpecifier} [conversionSpec]
###
formatNaN = (conversionSpec) ->
  adjustSignWidth(NAN, conversionSpec, '', ' ')

###*
  * Format an Infinity based on conversionSpec
  * @param {Number} [infValue]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
formatInfinity = (infValue, conversionSpec) ->
  adjustSignWidth(INFINITY, conversionSpec, getSignPrefix(infValue, conversionSpec), ' ')

###*
  * Translate one character to string
  * @param {String, Number} [value] Either a character, or an integer which will be converted to a character
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
formatChar = (value, conversionSpec) ->
  value_type = typeof(value)
  if value_type == 'number'
    if value % 1 != 0
      throw new Error("%c cannot consume an float value #{value}")
    value = String.fromCharCode(value)
  else if value_type == 'string'
    if value.length != 1
      throw new Error("Expecting one character, got a string #{value} with length #{value.length}")
  else
    throw new Error("Expecting one character or a number that can be converted to character, got #{value_type}")
  adjustSignWidth(value, conversionSpec)

###*
  * Translate a number into string
  * @param {Number} [value]
  * @param {ConversionSpecifier} [conversionSpec]
  * @param {Function} [formatRepresentableValueFunc]
  * @return {String}
###
formatNumber = (value, conversionSpec, formatRepresentableValueFunc) ->
  if isNaN(value)
    formatNaN(conversionSpec)
  else if !isFinite(value)
    formatInfinity(value, conversionSpec)
  else
    formatRepresentableValueFunc(value, conversionSpec)

###*
  * Format an integer
  * @param {Number} [intValue]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
formatInteger = (intValue, conversionSpec) ->
  result = ''

  # Special case, when value is 0 && precision is 0, there is no digit
  if !(intValue == 0 && conversionSpec.precision == 0)
    result = Math.abs(intValue).toString()
    if result.length < conversionSpec.precision
      result = Array(conversionSpec.precision - result.length + 1).join('0') + result

  adjustSignWidth(result, conversionSpec, getSignPrefix(intValue, conversionSpec))

###*
  * Format an oct
  * @param {Number} [intValue]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
formatOct = (intValue, conversionSpec) ->
  throw new Error("Expecting a positive integer, got #{intValue}") unless intValue >= 0

  result = ''

  # Special case, when value is 0 && precision is 0, there is no digit
  if !(intValue == 0 && conversionSpec.precision == 0)
    result = Math.abs(intValue).toString(8)

    if result.length < conversionSpec.precision
      result = Array(conversionSpec.precision - result.length + 1).join('0') + result

  if conversionSpec.hasFlag('#') && result[0] != '0'
    result = '0' + result

  adjustSignWidth(result, conversionSpec, '')

###*
  * Format a hex
  * @param {Number} [intValue]
  * @param {ConversionSpecifier} [conversionSpec]
  * @param {Boolean} [upperCase]
  * @return {String}
###
formatHex = (intValue, conversionSpec, upperCase) ->
  throw new Error("Expecting a positive integer, got #{intValue}") unless intValue >= 0

  result = ''

  # Special case, when value is 0 && precision is 0, there is no digit
  if !(intValue == 0 && conversionSpec.precision == 0)
    result = Math.abs(intValue).toString(16)

    if upperCase
      result = result.toUpperCase()
    if result.length < conversionSpec.precision
      result = Array(conversionSpec.precision - result.length + 1).join('0') + result

  prefix = ''
  if conversionSpec.hasFlag('#') && intValue != 0
    prefix = '0x'

  adjustSignWidth(result, conversionSpec, prefix)

###*
  * Format a float number
  * @param {Number} [floatValue]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
formatFloat = (floatValue, conversionSpec) ->
  result = ''

  if conversionSpec.precision == 0
    result = Math.abs(toFixedRound(floatValue, 0)).toString()
    if conversionSpec.hasFlag('#')
      result += '.'
  else
    result = toFixedRound(Math.abs(floatValue), conversionSpec.precision)

  adjustSignWidth(result, conversionSpec, getSignPrefix(floatValue, conversionSpec))

###*
  * Format a float to string, using scientific notation
  * @param {Number} [floatValue]
  * @param {ConversionSpecifier} [conversionSpec]
  * @param {Boolean} {upperCase}
  * @return {String}
###
formatExponential = (floatValue, conversionSpec, upperCase) ->
  [val, expTerm] = toExponential(floatValue)

  floatFlag = ''
  if conversionSpec.hasFlag('#')
    floatFlag = '#'
  floatConversionSpecifier = new ConversionSpecifier(
    floatFlag, 0, conversionSpec.precision, 'f', true)

  valueStr = formatFloat(Math.abs(val), floatConversionSpecifier)
  expTermStr = formatInteger(expTerm, EXPONENTIAL_TERM_CONVERSION_SPECIFIER)

  eChar = 'e'
  if upperCase
    eChar = 'E'

  adjustSignWidth(valueStr + eChar + expTermStr, conversionSpec, getSignPrefix(floatValue, conversionSpec))

###*
  * Format a float to string, depending on the value converted and the precision
  *
###

###*
  * Format a string
  * @param {Object} [value]
  * @param {ConversionSpecifier} [conversionSpec]
  * @return {String}
###
formatString = (value, conversionSpec) ->
  result = String(value)
  if conversionSpec.precision && result.length > conversionSpec.precision
    result = result[0...conversionSpec.precision]
  adjustSignWidth(result, conversionSpec)

###*
  * Mapping function from conversion specifier
  * @type {Hash}
  * @const
###
CONVERSION_SPECIFIER_FUNCTIONS = {
  c: (value, conversionSpec) -> formatChar(value, conversionSpec),
  d: (value, conversionSpec) -> formatNumber(value, conversionSpec, formatInteger),
  i: (value, conversionSpec) -> formatNumber(value, conversionSpec, formatInteger),
  o: (value, conversionSpec) -> formatNumber(value, conversionSpec, formatOct),
  x: (value, conversionSpec) -> formatNumber(
    value, conversionSpec,
    (_value, _conversionSpec) -> formatHex(_value, _conversionSpec, false)),
  X: (value, conversionSpec) -> formatNumber(
    value, conversionSpec,
    (_value, _conversionSpec) -> formatHex(_value, _conversionSpec, true)),
  f: (value, conversionSpec) -> formatNumber(value, conversionSpec,
    (_value, _conversionSpec) -> formatFloat(_value, _conversionSpec)),
  F: (value, conversionSpec) -> formatNumber(value, conversionSpec,
    (_value, _conversionSpec) -> formatFloat(_value, _conversionSpec)),
  e: (value, conversionSpec) -> formatExponential(value, conversionSpec),
  E: (value, conversionSpec) -> formatExponential(value, conversionSpec),
  s: (value, conversionSpec) -> formatString(value, conversionSpec)
}

###*
  * sprintf function
  * @param {String} [formatString]
  * @param {Arguments} [args]
  * @return {String}
###
(exports ? this).sprintf = (formatString, args...) ->
  formatStringLength = formatString.length
  formatStringIterator = 0

  argsLength = args.length
  argsIterator = 0

  resultString = ''

  ###*
    * Get the current character at formatStringIterator
    * @return {String}
  ###
  consumeFormatStringChar = ->
    if formatStringIterator >= formatStringLength
      null
    else
      formatString[formatStringIterator++]

  ###*
    * Get the current args
    * @return {Object}
  ###
  consumeArgument = ->
    if argsIterator >= argsLength
      throw new Error("Got #{argsLength} args, expecting more.")
    else
      args[argsIterator++]

  ###*
    * Interpret a matched conversion specifier
    * @param {Hash} [match]
    * @return {ConversionSpecifier}
  ###
  interpretConversionSpecifiersMatches = (match) ->
    width = parseInt(match[2]) or null
    if width == '*'
      width = parseInt(consumeArgument())
      throw new Error("Expecting an integer for width, got #{width}") unless width

    precision = getDefaultPrecision(match[6])
    if match[3]
      if !match[4]
        precision = 0
      else if match[4] == '*'
        precision = parseInt(consumeArgument())
        throw new Error("Expecting a positive integer for precision, got #{precision}") unless precision >= 0
      else
        precision = parseInt(match[4])

    new ConversionSpecifier(match[1], width, precision, match[5], match[6], !!match[3])

  ###*
    * Read a conversion specifier from format string
    * @return {Hash}
  ###
  readConversionSpecifier = ->
    match = CONVERSION_SPECIFIER_REGEXP.exec(formatString[formatStringIterator..])
    if match
      formatStringIterator += match[0].length
      match
    else
      throw new Error("Unable to parse a format specifier, starting at index #{formatStringIterator}. " +
          "The remaining string is '#{formatString}'")

  ###*
    * Apply conversion specifier to argument
    * @param {ConversionSpecifier} [conversionSpec]
    * @return {String}
  ###
  applyConversionSpecifier = (conversionSpec) ->
    specifier = conversionSpec.specifier
    if specifier == '%'
      '%'
    else
      if !CONVERSION_SPECIFIER_FUNCTIONS.hasOwnProperty(specifier)
        throw new Error("Unsupported specifier #{specifier}")
      else
        CONVERSION_SPECIFIER_FUNCTIONS[specifier](consumeArgument(), conversionSpec)

  char = consumeFormatStringChar()
  while(char)
    if char == '%'
      resultString += applyConversionSpecifier(interpretConversionSpecifiersMatches(readConversionSpecifier()))
    else
      resultString += char

    char = consumeFormatStringChar()

  resultString