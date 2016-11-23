(function() {


}).call(this);
(function() {


}).call(this);
$(document.body).ready(
    function () {
        var change = function () {
            $("#products-view-button").click(function() {
				$(".orders-view").removeClass("default")
				$(".orders-view").addClass("not-default")

				$(".products-view").removeClass("not-default")
				$(".products-view").addClass("default")
			});

			$("#orders-view-button").click(function() {
				$(".orders-view").removeClass("not-default")
				$(".orders-view").addClass("default")

				$(".products-view").removeClass("default")
				$(".products-view").addClass("not-default")
			});
        }
        change();  //call it when the page is loaded
    }
);


(function() {


}).call(this);
(function() {


}).call(this);
(function() {


}).call(this);
// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//


;
