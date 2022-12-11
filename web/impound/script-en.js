$(document).ready(function () {
  var documentWidth = document.documentElement.clientWidth;
  var documentHeight = document.documentElement.clientHeight;

  $('.lds-ellipsis').hide();

  // Retrieval form vars
  var rData = null;
  var rReason = document.getElementById('r-reason');
  var holdBy = document.getElementById('hold-by');

  var rules = null;

  window.addEventListener('message', function (event) {
    var data = event.data;
    rules = event.data.rules;

    if (data.action === 'open') {
      if (data.form === 'impound') {
        $('#impound-form').css('display', 'flex');
        setupImpoundForm(data);
      }

      if (data.form === 'retrieve') {
        $('#retrieve-form').css('display', 'flex');
        setupRetrievalForm(data);
      }

      if (data.form === 'admin') {
        $('#admin-terminal').css('display', 'flex');
        setupAdminTerminal(data);
      }
    }

    if (data.action == 'close') {
      $('#impound-form').css('display', 'none');
      $('#retrieve-form').css('display', 'none');
      $('#admin-terminal').css('display', 'none');
    }
  });

  // On 'Esc' call close method
  document.onkeyup = function (data) {
    if (data.which == 27) {
      $.post('http://mg_realparking/escape', JSON.stringify({}));
    }
  };

  function setupImpoundForm(data) {
    if (data.officer) {
      $('#officer').text(data.officer);
    }

    if (data.job) {
      $('#officerjob').text(data.job);
    }

    $('#owner').text(data.vehicle.owner);
    $('#plate').text(data.vehicle.plate);
    $('#parkingprice').text(`$${data.vehicle.parkingprice}`);
    $('#fee').attr('placeholder', `${rules.minFee} - ${rules.maxFee}`);
    $('#reason').attr('placeholder', `Write a description of at least ${rules.minReasonLength} characters`);
  }

  $('#impound').click(function (event) {
    if (validateImpoundForm()) {
      $('.impound-submit-button').prop('disabled', true);
      $('.lds-ellipsis').show();

      $.post(
        'http://mg_realparking/impound',
        JSON.stringify({
          plate: $('#plate').text(),
          fee: $('#fee').val(),
          reason: $('#reason').val(),
          notes: $('#notes').val() || null
        })
      ).always(function () {
        $('.lds-ellipsis').hide();
        $('.impound-submit-button').prop('disabled', false);
      });
    }
  });

  function validateImpoundForm() {
    var success = true;
    var errors = $('#errors');
    errors.empty();
    var fee = $('#fee').val();
    var reason = $('#reason').val();

    if (fee.isNaN || String(fee).length < 1 || parseInt(fee) < rules.minFee || parseInt(fee) > rules.maxFee) {
      errors.append(
        `<small>&#9679; The fine cannot be less than ${rules.minFee} nor more than ${rules.maxFee}</small>`
      );
      success = false;
    }

    if (reason.length < rules.minReasonLength || reason.length > 10000) {
      errors.append(
        `<small>&#9679; You must put a valid reason of at least ${rules.minReasonLength} characters.</small>`
      );
      success = false;
    }

    return success;
  }

  function setupRetrievalForm(data) {
    var vehicleHtml = '';
    rData = data;

    for (var i = 0; i < data.vehicles.length; i++) {
      var row = `<tr>
				<td id="plate">${data.vehicles[i].plate}</td>
        <td id="price">$<strong>${data.vehicles[i].fee}</strong></td>
        <td id="parkingfee">$<strong>${data.vehicles[i].impoundParkingFee}</strong></td>
        <td id="job">${data.vehicles[i].label}</td>
        <td id="officer">${data.vehicles[i].firstname}</td>
        <td id="parking">$<strong>${data.vehicles[i].parkingprice}</strong></td>
        <td id="total">$<strong>${data.vehicles[i].totalprice}</strong></td>
        `;

      if (data.money < data.vehicles[i].fee) {
        button = `<td>
					<button class="btn info mr" id="info${i}">INFO</button>
					<button class="btn pay success" disabled>NOT MONEY</button>
				</td></tr>`;
      } else {
        button = `<td>
					<button class="btn info mr" id="info${i}">INFO</button>
					<button class="btn pay success" id="${i}">PAY</button>
				</td></tr>`;
      }

      row = row + button;
      vehicleHtml = vehicleHtml + row;

      $('#reasonDiv').hide();
      $('#impounded-vehicles').html(vehicleHtml);
    }
  }

  $('table').on('click', '.pay', function () {
    var plate = $(this).parent().parent().find('#plate').text();
    $.post('http://mg_realparking/unimpound', JSON.stringify(plate));
  });

  $('#close-reason').on('click', function () {
    $('#reasonDiv').hide();
  });

  $('table').on('click', '.info', function () {
    var index = $(this).attr('id');
    index = index.replace('info', '');
    $('#reasonDiv').show();
    $('#vehName').html(rData.vehicles[parseInt(index)].vehName);
    $(rReason).text(rData.vehicles[parseInt(index)].reason);
  });

  $('#cancel, #exit').click(function (event) {
    $.post('http://mg_realparking/escape', null);
  });
});
