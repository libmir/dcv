
var docs = [
    "dcv_core_algorithm.html", 
    "dcv_core_image.html", 
    "dcv_core_memory.html", 
    "dcv_core_utils.html", 
    "dcv_features_corner_fast_package.html", 
    "dcv_features_corner_harris.html", 
    "dcv_features_corner_package.html", 
    "dcv_features_detector_package.html", 
    "dcv_features_utils.html", 
    "dcv_imgproc_color.html", 
    "dcv_imgproc_convolution.html", 
    "dcv_imgproc_filter.html", 
    "dcv_imgproc_imgmanip.html", 
    "dcv_imgproc_interpolate.html", 
    "dcv_imgproc_threshold.html", 
    "dcv_io_image.html", 
    "dcv_io_package.html", 
    "dcv_io_video_common.html", 
    "dcv_io_video_input.html", 
    "dcv_io_video_output.html", 
    "dcv_plot_draw.html", 
    "dcv_plot_opticalflow.html", 
    "dcv_tracking_opticalflow_hornschunck.html", 
    "dcv_tracking_opticalflow_lucaskanade.html", 
    "dcv_tracking_opticalflow_pyramidflow.html", 
    "dcv_tracking_opticalflow_package.html", 
    "dcv_tracking_opticalflow_base.html", 
    ];

var examples = [
    "example_filter.html",
    "example_features.html",
    "example_video.html",
    "example_tracking_hornschunck.html",
    "example_tracking_lucaskanade.html",
    "example_imgmanip.html"
];

var DESKTOP_UI = 0;
var PHONE_UI = 1;
var DESKTOP_MIN_WIDTH = 1200;
var CONTENT_SYMB_UP = 'Content ▲';
var CONTENT_SYMB_DOWN = 'Content ▼';

var PROJECT_BOX_WIDTH = "88%"
var PROJECT_BOX_WIDTH_PHONE = "60%";
var PROJECT_BOX_WIDTH_SHRUNK = "65%";

var animationSpeed = 200;
var currentUI = DESKTOP_UI; 

function replaceAll(str, find, replace) {
    return str.replace(new RegExp(find, 'g'), replace);
}

function hideContent() {
    if (currentUI == DESKTOP_UI) {
        $("#projectbox").animate(
                {width: PROJECT_BOX_WIDTH}, 
                {duration: animationSpeed, queue:false}
                );
    }
    $("#sourcetreebox").hide(animationSpeed);

}

function showContent() {
    if (currentUI == DESKTOP_UI) {
        $("#projectbox").animate(
                {width: PROJECT_BOX_WIDTH_SHRUNK}, 
                {duration: animationSpeed, queue:false}
                );
    }
    $("#sourcetreebox").show(animationSpeed);
    $("#content").text(CONTENT_SYMB_DOWN);
}

function toggleContent() {
    $("#sourcetree").children('li').toggle(animationSpeed);
    if ($("#content").text() == CONTENT_SYMB_UP) {
        $("#content").text(CONTENT_SYMB_DOWN);
    } else {
        $("#content").text(CONTENT_SYMB_UP);
    }
}

function setupHome() {
    $("#projectbox").animate({width: PROJECT_BOX_WIDTH}, {duration:animationSpeed, queue:false});
    $("#sourcetreebox").hide(animationSpeed, function() {
        window.location.href = "index.html";
    });
}

function setupContent(content) {
    var sourcetree = document.getElementById("sourcetree");
    sourcetree.innerHTML = '';

    if (content.length == 0) {
        hideContent();
        return;
    } 

    content.forEach(function(item, index) {
        var lis = "";
        var itemtokens = item.split("/");
        var itempretty = itemtokens[itemtokens.length-1].replace(".html", "");
        itempretty = replaceAll(itempretty, "_", ".");
        itempretty = replaceAll(itempretty, ".package", "");
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

function setupDocumentation() {
    setupContent(docs);
}

function setupExamples() {
    setupContent(examples);
}

function setupPhoneUI() {
    animationSpeed = 0;
    $("#sourcetree").children('li').slideUp(animationSpeed);
    $(".roundedbox").css("border-radius", "0px");
    $("#sourcetreebox").css("width", $("#projectbox").css("width"));
    $("#sourcetreebox").css('min-height', '0');
    $('#return-to-top').hide();
    hideContent();
}

function setupDesktopUI() {
    animationSpeed = 200;
    $(".roundedbox").css("border-radius", "16px");
    $("#sourcetreebox").css("width", "270px");
    $("#sourcetreebox").css('min-height', '500px');
    $("#projectbox").css("width", PROJECT_BOX_WIDTH);

    hideContent();
}

function evalSize() {
    screenWidth = window.innerWidth;
    if (screenWidth < DESKTOP_MIN_WIDTH) {
        setupPhoneUI();
        currentUI = PHONE_UI;
    } else {
        setupDesktopUI();
        currentUI = DESKTOP_UI;
    }
}


$(document).ready(function(e) {


    // setup content toggle
    $("#content").click(toggleContent);

    // always hide the source tree box on startup
    $("#sourcetreebox").hide();

    document.getElementById("homelink").onclick = setupHome;
    document.getElementById("doclink").onclick = setupDocumentation;
    document.getElementById("exampleslink").onclick = setupExamples;
    window.onresize = evalSize;

    // setup return-to-top behaviour
    $(window).scroll(function() {
        if ($(this).scrollTop() >= 50) {
            $('#return-to-top').fadeIn(animationSpeed);
        } else {
            $('#return-to-top').fadeOut(animationSpeed);
        }
    });

    $('#return-to-top').click(function() {
        $('body,html').animate({
            scrollTop : 0
        }, animationSpeed*2);
    });

    evalSize();
});

