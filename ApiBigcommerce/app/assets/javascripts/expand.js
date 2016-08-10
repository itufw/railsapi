$(document).on('page:change', function() {
	
	$("#products-view-button").click(function() {
		$(".orders-view").css("display", "none")

		$("#products-view-table").css("display", "table")
		$("#products-view-heading").css("display", "block")

		$("#orders-view-button").css("background-color", "#e7e7e7")
		$("#orders-view-button").css("color", "black")

		$("#products-view-button").css("background-color", "#4CAF50")
		$("#products-view-button").css("color", "white")

	});
	
	$("#orders-view-button").click(function() {

		$(".products-view").css("display", "none")

		$("#orders-view-table").css("display", "table")
		$("#orders-view-heading").css("display", "block")

		$("#products-view-button").css("background-color", "#e7e7e7")
		$("#products-view-button").css("color", "black")

		$("#orders-view-button").css("background-color", "#4CAF50")
		$("#orders-view-button").css("color", "white")
		
	});
})
