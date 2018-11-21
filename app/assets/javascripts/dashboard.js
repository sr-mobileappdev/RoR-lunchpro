document.addEventListener("turbolinks:load", function() {
  orders_pie_chart1 = document.getElementById("pie-chart-1")
  chart1_div = $('#chart1');

  new Chart(orders_pie_chart1.getContext('2d'), {
      type: 'pie',
      data: {
        labels: chart1_div.data().labels,
        datasets: [{
          label: "Orders",
          backgroundColor: [
            'rgba(255, 99, 132, 0.5)',
            'rgba(54, 162, 235, 0.5)',
            'rgba(75, 192, 192, 0.5)',
            'rgba(153, 102, 255, 0.5)'
          ],
          data: chart1_div.data().chart
        }]
      },
      options: {
        title: {
          display: true,
          text: 'MTD Orders Placed by Role'
        },
        rotation: -.9,
        animation: {
          animateRotate: true,
          duration: 1500
        }
      }
  });

  orders_pie_chart2 = document.getElementById("pie-chart-2")
  chart2_div = $('#chart2');

  new Chart(orders_pie_chart2.getContext('2d'), {
      type: 'pie',
      data: {
        labels: chart2_div.data().labels,
        datasets: [{
          label: "Orders",
          backgroundColor: [
            'rgba(255, 99, 132, 0.5)',
            'rgba(54, 162, 235, 0.5)',
            'rgba(75, 192, 192, 0.5)',
            'rgba(153, 102, 255, 0.5)'
          ],
          data: chart2_div.data().chart
        }]
      },
      options: {
        title: {
          display: true,
          text: 'MTD Orders Placed by User Ranking'
        },
        animation: {
          animateRotate: true,
          duration: 1500
        }
      }
  });

  appointment_dist = document.getElementById("appt-dist")
  chart3_div = $('#chart3');

  new Chart(appointment_dist.getContext('2d'), {
      type: 'doughnut',
      data: {
        labels: chart3_div.data().labels,
        datasets: [{
          label: "Appointments",
          backgroundColor: [
            'rgba(255, 99, 132, 0.5)',
            'rgba(54, 162, 235, 0.5)',
            'rgba(75, 192, 192, 0.5)',
            'rgba(153, 102, 255, 0.5)',
            'rgba(255, 159, 64, 0.5)'
          ],
          data: chart3_div.data().chart
        }]
      },
      options: {
        title: {
          display: true,
          text: 'Appointment Distribution'
        },
        animation: {
          animateRotate: true,
          duration: 1500
        }
      }
  });

});
