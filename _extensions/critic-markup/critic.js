function critic() {

    $('.fullcontent').addClass('markup');
    $('#markup-button').addClass('active');
    $('ins.break').unwrap();
    $('span.critic.comment').wrap('<span class="popoverc" /></span>');
    $('span.critic.comment').before('&#8225;');
}

function original() {
    $('#original-button').addClass('active');
    $('#edited-button').removeClass('active');
    $('#markup-button').removeClass('active');

    $('.fullcontent').addClass('original');
    $('.fullcontent').removeClass('edited');
    $('.fullcontent').removeClass('markup');
}

function edited() {
    $('#original-button').removeClass('active');
    $('#edited-button').addClass('active');
    $('#markup-button').removeClass('active');

    $('.fullcontent').removeClass('original');
    $('.fullcontent').addClass('edited');
    $('.fullcontent').removeClass('markup');
} 

function markup() {
    $('#original-button').removeClass('active');
    $('#edited-button').removeClass('active');
    $('#markup-button').addClass('active');

    $('.fullcontent').removeClass('original');
    $('.fullcontent').removeClass('edited');
    $('.fullcontent').addClass('markup');
}

var o = document.getElementById("original-button");
var e = document.getElementById("edited-button");
var m = document.getElementById("markup-button");

window.onload = critic();
o.onclick = original;
e.onclick = edited;
m.onclick = markup;
