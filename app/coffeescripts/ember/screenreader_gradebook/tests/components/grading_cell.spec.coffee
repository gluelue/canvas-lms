define [
  'ember'
  '../start_app'
  '../shared_ajax_fixtures'
], (Ember, startApp, fixtures) ->

  {ContainerView, run} = Ember
  originalChangeGrade = null

  fixtures.create()

  setType = null

  module 'grading_cell',
    setup: ->
      App = startApp()
      @component = App.GradingCellComponent.create()

      setType = (type) =>
        run => @assignment.set('grading_type', type)
      @component.reopen
        changeGradeURL: ->
          originalChangeGrade = this._super
          "/api/v1/assignment/:assignment/:submission"
      run =>
        @submission = Ember.Object.create
          grade: 'A'
          assignment_id: 1
          user_id: 1
        @assignment = Ember.Object.create
          grading_type: 'points'
        @component.setProperties
          'submission': @submission
          assignment: @assignment
        @component.append()

    teardown: ->
      run =>
        @component.destroy()
        App.destroy()

  test "setting value on init", ->
    component = App.GradingCellComponent.create()
    equal(component.get('value'), '-')

    equal(@component.get('value'), 'A')


  test "saveURL", ->
    equal(@component.get('saveURL'), "/api/v1/assignment/1/1")

  test "isPoints", ->
    setType 'points'
    ok @component.get('isPoints')

  test "isPercent", ->
    setType 'percent'
    ok @component.get('isPercent')

  test "isLetterGrade", ->
    setType 'letter_grade'
    ok @component.get('isLetterGrade')


  asyncTest "focusOut", ->
    stub = sinon.stub @component, 'boundUpdateSuccess'
    submissions = []

    requestStub = null
    run =>
      requestStub = Ember.RSVP.resolve all_submissions: submissions

    sinon.stub(@component, 'ajax').returns requestStub

    run =>
      @component.$('input').val('ohi')
      @component.send('focusOut')

      requestStub.then ->
        start()
        ok stub.called

