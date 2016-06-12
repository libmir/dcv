
var docs = [
    "dcv_core_algorithm.html", 
    "dcv_core_image.html", 
    "dcv_core_memory.html", 
    "dcv_core_utils.html", 
    "dcv_features_corner_harris.html", 
    "dcv_features_utils.html", 
    "dcv_imgproc_color.html", 
    "dcv_imgproc_convolution.html", 
    "dcv_imgproc_filter.html", 
    "dcv_imgproc_imgmanip.html", 
    "dcv_imgproc_interpolate.html", 
    "dcv_imgproc_threshold.html", 
    "dcv_io_image.html", 
    "dcv_io_video_common.html", 
    "dcv_io_video_input.html", 
    "dcv_io_video_output.html", 
    "dcv_plot_draw.html", 
    "dcv_plot_opticalflow.html", 
    "dcv_tracking_opticalflow_hornschunck.html", 
    "dcv_tracking_opticalflow_lucaskanade.html", 
    "dcv_tracking_opticalflow_pyramidflow.html"
    ];

    var examples = [

    ];

    var animationSpeed = 200;

    function replaceAll(str, find, replace) {
        return str.replace(new RegExp(find, 'g'), replace);
    }

function hideContent() {
    $("#projectbox").animate(
            {width: '88%'}, 
            {duration: animationSpeed, queue:false}
            );
    $("#sourcetreebox").hide(animationSpeed);

}

function showContent() {
    $("#projectbox").animate(
            {width: '69%'}, 
            {duration: animationSpeed, queue:false}
            );
    $("#sourcetreebox").show(animationSpeed);
}

function setupHome() {
    $("#projectbox").animate({width: '88%'}, {duration:animationSpeed, queue:false});
    $("#sourcetreebox").hide(animationSpeed, function() {
        window.location.href = "index.html";
    });
}


function setupDocumentation() {

    var sourcetree = document.getElementById("sourcetree");
    sourcetree.innerHTML = '';

    if (docs.length == 0) {
        hideContent();
        return;
    } 

    docs.forEach(function(item, index) {
        var lis = "";
        var itemtokens = item.split("/");
        var itempretty = itemtokens[itemtokens.length-1].replace(".html", "");
        itempretty = replaceAll(itempretty, "_", ".");
        lis += "<a href=\"#\">";
        lis += itempretty;
        lis += "</a>\n";


        var li = document.createElement("li");
        li.innerHTML = lis;
        var htmlLoadFunc = function() {
            var html = $.ajax({
                url : item,
                dataType : 'text',
                success: function(result) {
                    document.getElementById("pagemain").innerHTML = result;
                }
            });
        };
        li.onclick = htmlLoadFunc;
        sourcetree.appendChild(li);
    });
    showContent();
}

function setupExamples() {

    var sourcetree = document.getElementById("sourcetree");
    sourcetree.innerHTML = '';

    var li = document.createElement("li");
    li.innerHTML = "Sorry, no examples at this moment.";
    sourcetree.appendChild(li);

    showContent();
}


$(document).ready(function(e) {

    $("#sourcetreebox").hide();

    document.getElementById("homelink").onclick = setupHome;
    document.getElementById("doclink").onclick = setupDocumentation;
    document.getElementById("exampleslink").onclick = setupExamples;

});

