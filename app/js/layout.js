var _gaq = _gaq || [];
_gaq.push(["_setAccount", "UA-33552646-1"]);
_gaq.push(["_setDomainName", "hike.io"]);
_gaq.push(["_trackPageview"]);

(function() {
	var ga = document.createElement("script"); ga.type = "text/javascript"; ga.async = true;
	ga.src = ("https:" == document.location.protocol ? "https://ssl" : "http://www") + ".google-analytics.com/ga.js";
	var s = document.getElementsByTagName("script")[0]; s.parentNode.insertBefore(ga, s);


	var disableNonTouchFeatures = function() {
		if ("ontouchstart" in document) {
    		$("body").removeClass("no-touch");
		}
	};

	$(document).ready(function() {
		disableNonTouchFeatures();
	});
}
)();