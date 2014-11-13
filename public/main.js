var disableLink = function(l){
  l.attr('data-text',l.text())
  l.text('Loading...');
  l.attr('disabled',true);
}
var restoreLink = function(l){
  l.text(l.attr('data-text'));
  l.attr('disabled',false);
}
var activatePopoverLinks = function(c){
  c.find('.ticket-info .actions .btn').on('click',function(e){
    e.preventDefault();
    var l = $(this)
    var target = l.attr('data-target');
    var type = (l.hasClass("checkout-link")) ? "checkout" : "checkin";
    if((type == "checkout" && confirm('Really want to checkout?')) || type == "checkin"){
      disableLink(l);
      $.get(target,function(response){
        restoreLink(l);
        if(type == "checkin"){
          $("#ticketrow-"+response['ticket_token']).find('.checkin-label').show();
          $("#ticketrow-"+response['ticket_token']).find('.checkout-label').hide();
        }
        if(type == "checkout"){
          $("#ticketrow-"+response['ticket_token']).find('.checkin-label').hide();
          $("#ticketrow-"+response['ticket_token']).find('.checkout-label').show();
        }
      });
    }
  });
}

$(function(){
  var lastPopover = null;
  // only one tooltip should ever be open at a time
  $('.has-popover').on('show.bs.tooltip', function() {
    if(lastPopover != null){
      var isSameLink = (lastPopover.attr("id") == $(this).attr("id"))
      if(!isSameLink) lastPopover.popover('hide');
    }
    lastPopover = $(this);
  })
  // reactivate links when we are visible again
  $('.has-popover').on('shown.bs.tooltip', function() {
    activatePopoverLinks($(this).parent());
  });
  // open tooltip on click and get content through xhr
  $('.has-popover').on('click',function() {
    var link = $(this);
    // only first click loads the content
    link.unbind('click');
    c = $("<div />").css("height",165);
    link.popover({html:true, content: c}).popover('show');
    $.get(link.data('poload'),function(d) {
      c.html(d);
      activatePopoverLinks(c);
    });
  });
});
