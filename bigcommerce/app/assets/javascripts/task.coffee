# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".task_function_selection").on "change", ->
    $.ajax
      url: "/task/add_task"
      type: "GET"
      dataType: "script"
      data:
        function_name: $('.task_function_selection option:selected').val()
