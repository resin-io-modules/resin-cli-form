m = require('mochainon')
inquirer = require('inquirer')
utils = require('../lib/utils')

describe 'Utils:', ->

	describe '.flatten()', ->

		describe 'given a form group', ->

			beforeEach ->
				@form = [
					{
						isGroup: true
						name: 'network'
						message: 'Network'
						isCollapsible: true
						collapsed: false
						options: [
							message: 'Network Connection'
							name: 'network'
							type: 'list'
							choices: [ 'ethernet', 'wifi' ]
						]
					}
					{
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					}
				]

			it 'should ignore the grouping and include all the questions', ->
				questions = utils.flatten(@form)
				m.chai.expect(questions).to.deep.equal [
					{
						message: 'Network Connection'
						name: 'network'
						type: 'list'
						choices: [ 'ethernet', 'wifi' ]
					}
					{
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					}
				]

		describe 'given a form group that contains a group', ->

			beforeEach ->
				@form = [
					{
						isGroup: true
						name: 'network'
						message: 'Network'
						isCollapsible: true
						collapsed: false
						options: [
							{
								isGroup: true
								name: 'network'
								message: 'Network'
								isCollapsible: true
								collapsed: false
								options: [
									message: 'Network Connection'
									name: 'network'
									type: 'list'
									choices: [ 'ethernet', 'wifi' ]
								]
							}
							{
								message: 'Wifi Passphrase'
								name: 'wifiKey'
								type: 'text'
							}
						]
					}
					{
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					}
				]

			it 'should deep flatten the group options', ->
				questions = utils.flatten(@form)
				m.chai.expect(questions).to.deep.equal [
					{
						message: 'Network Connection'
						name: 'network'
						type: 'list'
						choices: [ 'ethernet', 'wifi' ]
					}
					{
						message: 'Wifi Passphrase'
						name: 'wifiKey'
						type: 'text'
					}
					{
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					}
				]

	describe '.parse()', ->

		describe 'given a simple question', ->

			beforeEach ->
				@form = [
					message: 'Network type'
					name: 'network'
					type: 'input'
					default: 'wifi'
				]

			it 'should parse the question correctly', ->
				questions = utils.parse(@form)
				m.chai.expect(questions).to.deep.equal [
					message: 'Network type'
					name: 'network'
					type: 'input'
					default: 'wifi'
				]

		describe 'given a question with an when property', ->

			describe 'given a single value when', ->

				beforeEach ->
					@form = [
						message: 'Coprocessor cores'
						name: 'coprocessorCore'
						type: 'list'
						choices: [ '16', '64' ]
						when:
							processorType: 'Z7010'
					]

				it 'should return a when function', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when).to.be.a('function')

				it 'should return true if the condition is met', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when(processorType: 'Z7010')).to.be.true

				it 'should return false if the condition is not met', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when(processorType: 'Z7020')).to.be.false

				it 'should return false if the property does not exist', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when(foo: 'Z7020')).to.be.false

				it 'should return false if no answer', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when()).to.be.false
					m.chai.expect(questions[0].when({})).to.be.false

			describe 'given a multiple value when', ->

				beforeEach ->
					@form = [
						message: 'Coprocessor cores'
						name: 'coprocessorCore'
						type: 'list'
						choices: [ '16', '64' ]
						when:
							processorType: 'Z7010'
							hdmi: true
					]

				it 'should return true if all the conditions are met', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when(processorType: 'Z7010', hdmi: true)).to.be.true

				it 'should return false if any condition is not met', ->
					questions = utils.parse(@form)
					m.chai.expect(questions[0].when(processorType: 'Z7020', hdmi: false)).to.be.false

		describe 'given a form group', ->

			beforeEach ->
				@form = [
					{
						isGroup: true
						name: 'network'
						message: 'Network'
						isCollapsible: true
						collapsed: false
						options: [
							message: 'Network Connection'
							name: 'network'
							type: 'list'
							choices: [ 'ethernet', 'wifi' ]
						]
					}
					{
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					}
				]

			it 'should ignore the grouping and include all the questions', ->
				questions = utils.parse(@form)
				m.chai.expect(questions).to.deep.equal [
					{
						message: 'Network Connection'
						name: 'network'
						type: 'list'
						choices: [ 'ethernet', 'wifi' ]
					}
					{
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					}
				]

	describe '.prompt()', ->

		describe 'given a single question form', ->

			beforeEach ->
				@inquirerPromptStub = m.sinon.stub(inquirer, 'prompt')
				@inquirerPromptStub.yields({ processorType: 'bar' })

			afterEach ->
				@inquirerPromptStub.restore()

			it 'should eventually be the result', ->
				promise = utils.prompt [
					message: 'Processor'
					name: 'processorType'
					type: 'list'
					choices: [ 'Z7010', 'Z7020' ]
				]

				m.chai.expect(promise).to.eventually.become(processorType: 'bar')

		describe 'given a multiple question form', ->

			beforeEach ->
				@inquirerPromptStub = m.sinon.stub(inquirer, 'prompt')
				@inquirerPromptStub.yields
					processorType: 'Z7010'
					coprocessorCore: '16'

			afterEach ->
				@inquirerPromptStub.restore()

			it 'should eventually become the answers', ->
				promise = utils.prompt [
						message: 'Processor'
						name: 'processorType'
						type: 'list'
						choices: [ 'Z7010', 'Z7020' ]
					,
						message: 'Coprocessor cores'
						name: 'coprocessorCore'
						type: 'list'
						choices: [ '16', '64' ]
				]

				m.chai.expect(promise).to.eventually.become
					processorType: 'Z7010'
					coprocessorCore: '16'
