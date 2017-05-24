/*global $*/
/*global pusher*/

$(function () {

  $(document).on('submit', '[data-pagelet-url] form:not(.no-trigger)', function (event) {
    var form = this
    var pagelet = $(form).closest('[data-pagelet-url]')
    pagelet.css('opacity', '0.3')
    $.post($(form).attr('action'), $(form).serialize(), function () {
      pagelet.load(pagelet.attr('data-pagelet-url'), function () {
        pagelet.css('opacity', '1')
      })
    })
    return false
  })

  $(document).on('click', '[data-pagelet-url] a.pagelet-trigger', function (event) {
    var a = this
    if ($(a).hasClass('no-trigger')) {
      $(a).removeClass('no-trigger')
      return false
    }
    var pagelet = $(a).closest('[data-pagelet-url]')
    pagelet.css('opacity', '0.3')
    $.get($(a).attr('href'), function () {
      pagelet.load(pagelet.attr('data-pagelet-url'), function () {
        pagelet.css('opacity', '1')
      })
    })
    return false
  })

  $(document).on('click', '[data-pagelet-url] .pagination a', function (event) {
    var a = this
    var pagelet = $(a).closest('[data-pagelet-url]')
    pagelet.css('opacity', '0.3')
    pagelet.load($(a).attr('href'), function () {
      pagelet.css('opacity', '1')
    })
    return false
  })

  function pageletPusher() {
    $('[data-pusher-channel]:not([data-pusher-channel-registered])').each(function () {
      var pagelet = $(this)
      var channel = pusher.subscribe(pagelet.attr('data-pusher-channel'));
      channel.bind('updated', function (data) {
        if ($(document).find(pagelet).length == 1) { // only proceed if this pagelet still exists in the DOM, to prevent unnecessary calls to .load()
          $(pagelet).load($(pagelet).attr('data-pagelet-url'))
        }
      });
      $(pagelet).attr('data-pusher-channel-registered', 'true')
    });
  }

  $(document).ajaxComplete(function () {
    pageletPusher()
  })
  pageletPusher()

  $('[data-pagelet-url]').each(function () {
    var pagelet = this;
    if ($(pagelet).html().length == 0)
      $(pagelet).load($(pagelet).attr('data-pagelet-url'))
  })


});