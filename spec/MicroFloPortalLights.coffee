noflo = require 'noflo'
chai = require 'chai'

device = "ws://localhost:5555"

Runtime = require('noflo-runtime/src/RemoteSubGraph').RemoteSubGraph

describe 'MicroFlo Portal Lights', ->
  runtime = null

  before (done) ->
    done()
  after (done) ->
    done()

  describe 'Remote subgraph', ->
    def =
      label: "Ingress Table Arduino"
      description: ""
      type: "microflo"
      protocol: "websocket"
      address: device
      id: "2ef763ff-1f28-49b8-b58f-5c6a5c23af25"
      graph: "./graphs/PortalLights.fbp",

    it 'should have ports', (done) ->
      @timeout 100000
      runtime = new Runtime
      runtime.setDefinition def
      checkPorts = () ->
        console.log Object.keys runtime.inPorts.ports
        console.log Object.keys runtime.outPorts.ports
        chai.expect(runtime.inPorts.ports['pixel']).to.be.an 'object'
        chai.expect(runtime.inPorts.ports['show']).to.be.an 'object'
        chai.expect(runtime.outPorts.ports['shown']).to.be.an 'object'
        done()
      return checkPorts() if runtime.isReady()
      runtime.once 'ready', () ->
        checkPorts()

    describe 'sending input data', () ->
      ###
      input = [
        37 # Light IDX
        "0x000000" # Accent color
        "0x000000" # Base color
        1000 # Period ms
        50 # Duty cycle %
        0 # Offset ms
        0 # Length ms
      ]
      ###
      input = [ 30, "0xFF00FF" ]

      it 'should respond with the same data', (done) ->
        insocket = noflo.internalSocket.createSocket()
        output = noflo.internalSocket.createSocket()
        runtime.inPorts["pixel"].attach insocket
        runtime.outPorts["pixelset"].attach output
        output.once 'data', (data) ->
          chai.expect(data).to.deep.equal input
        done()
        insocket.send input


