fs = require 'fs'
path = require 'path'

arduino_build = (name, options) ->
  # Wrapper around the `arduino-builder` CLI tool setting up the neccesary paths
  defaults =
    board: 'arduino:avr:uno'
    sketch: "build/arduino/#{name}/#{name}.#{options.ext||'cpp'}"
    arduino: process.env.ARDUINO or process.env.HOME + '/arduino-1.8.1'
    'arm-none-eabi-gcc': '/home/jon/.arduino15/packages/arduino/tools/arm-none-eabi-gcc/4.8.3-2014q1'
    libraries: '/home/jon/Arduino/libraries'
    outdir: path.join(process.cwd(), "build/arduino/#{name}/builder/")

  for k,v of defaults
    options[k] = v if not options[k]?

  buildDir = path.join path.dirname(options.sketch), 'builder'
  builder = path.join options.arduino, 'arduino-builder'
  cmd = [
    builder,
    '-compile', ' -verbose'
    '-hardware', path.join(options.arduino, 'hardware')
    '-tools', path.join(options.arduino, 'tools-builder'),
    '-tools ', path.join(options.arduino, 'hardware', 'tools')
    '-libraries', options.libraries
    "-prefs=runtime.tools.arm-none-eabi-gcc.path=#{options['arm-none-eabi-gcc']}"
    '-fqbn', options.board
    '-build-path', options.outdir
    options.sketch
  ]
  return cmd.join(' ')

microflo_gen = (name, options={}) ->
  defaults =
    microflo: './node_modules/.bin/microflo'
    target: 'linux'
    out: "build/#{options.target||'linux'}/#{name}/#{name}.#{options.ext||'cpp'}"
    graph: "graphs/#{name}.fbp"
    library: "./components-#{name}.json"
  for k,v of defaults
    options[k] = v if not options[k]?

  dir = path.dirname options.out
  parent = path.dirname dir
  grandparent = path.dirname parent
  fs.mkdirSync grandparent if not fs.existsSync grandparent
  fs.mkdirSync parent if not fs.existsSync parent
  fs.mkdirSync dir if not fs.existsSync dir
  fs.mkdirSync path.join(dir,'builder') if not fs.existsSync path.join(dir,'builder')
  cmd = [
    options.microflo,
    '--target', options.target
    '--library', options.library
    'generate', options.graph, options.out
  ]
  return cmd.join(' ')

microflo_compile = (name, options={}) ->
  defaults =
    out: "build/#{options.target||'linux'}/#{name}/#{name}"
    in: "build/#{options.target||'linux'}/#{name}/#{name}.cpp"
  for k,v of defaults
    options[k] = v if not options[k]?
  cmd = [
    "g++ -g -Wall -Werror -Wno-unused-variable -DLINUX -std=c++0x"
    "-I./build -I./node_modules/microflo/microflo"
    "-o", options.out, options.in
    "-lrt -lutil"
  ]
  return cmd.join(' ')

#console.log microflo_make

module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    # Automated recompilation and testing when developing
    watch:
      files: ['spec/*.coffee', 'components/*.coffee']
      tasks: ['test']

    # BDD tests on Node.js
    mochaTest:
      nodejs:
        src: ['spec/*.coffee']
        options:
          reporter: 'spec'
          require: 'coffee-script/register'
          grep: process.env.TESTS

    # Coding standards
    coffeelint:
      components:
        files:
          src: ['components/*.coffee']
        options:
          max_line_length:
            value: 80
            level: 'warn'

    noflo_lint:
      graphs:
        options:
          description: 'ignore'
          icon: 'ignore'
          port_descriptions: 'ignore'
          asynccomponent: 'error'
          wirepattern: 'warn'
          process_api: 'ignore'
          legacy_api: 'ignore'
        files:
          src: [
            'graphs/main.json'
          ]

    # "$(node build.js build/arduino/PortalLights/PortalLights.cpp)"
  
    'string-replace':
      portallights:
        files:
          'build/arduino/PortalLights/PortalLights.ino': 'build/arduino/PortalLights/PortalLights.ino.tmpl'
        options:
          replacements: [
            pattern: '\n'
            replacement: '\n#include <Adafruit_WS2801.h>\n#define HAVE_ADAFRUIT_WS2801\n\n'
          ]

    exec:
      tablelights_arduino_gen: microflo_gen 'TableLights', { target: 'arduino' }
      tablelights_arduino_build: arduino_build 'TableLights', { board: 'energia:tivac:EK-TM4C123GXL' }
      tablelights_linux_gen: microflo_gen 'TableLights' 
      tablelights_linux_comp: microflo_compile 'TableLights'
      tablelights_run: './spec/microflo-linux.sh TableLights 4444 & sleep 5'
      portallights_arduino_gen: microflo_gen 'PortalLights', { target: 'arduino', ext: 'ino.tmpl' }
      portallights_arduino_build: arduino_build 'PortalLights', 
        board: 'arduino:avr:uno'
        ext: 'ino'
      portallights_linux_gen: microflo_gen 'PortalLights' 
      portallights_linux_comp: microflo_compile 'PortalLights'
      portallights_run: './spec/microflo-linux.sh PortalLights 5555 & sleep 5'
      kill_microflo_linux:
        options: { shell: '/bin/bash' }
        command: 'pkill microflo-linux || echo no processes to kill'

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-exec'
  @loadNpmTasks 'grunt-string-replace'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-contrib-watch'
  @loadNpmTasks 'grunt-mocha-test'
  @loadNpmTasks 'grunt-coffeelint'
  @loadNpmTasks 'grunt-noflo-lint'

  # Our local tasks
  @registerTask 'build-microflo-linux', [
    'exec:tablelights_linux_gen', 'exec:tablelights_linux_comp',
    'exec:portallights_linux_gen', 'exec:portallights_linux_comp',
  ]
  @registerTask 'build-microflo-arduino', [
    'exec:portallights_arduino_gen', 'string-replace:portallights', 'exec:portallights_arduino_build',
    'exec:tablelights_arduino_gen', 'exec:tablelights_arduino_build',

  ]
  @registerTask 'run-microflo-linux', [
    'exec:kill_microflo_linux'
    'exec:tablelights_run'
    'exec:portallights_run'
  ]
  @registerTask 'build', ['build-microflo-linux', 'build-microflo-arduino']
  @registerTask 'test', ['coffeelint', 'build', 'run-microflo-linux', 'mochaTest']

  @registerTask 'default', ['test']
