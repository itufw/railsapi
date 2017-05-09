# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".calendar-date").on "click", ->
    $.ajax
      url: "/local_calendar"
      type: "POST"
      dataType: "script"
      data:{
        calendar_date_selected: $(this).attr('date'),
        calendar_staff_selected: $(this).attr('staff-id')
      };
