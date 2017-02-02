$(function () {

    var Animation = function(data) {
        this.isPaused = false;
        this.data = data;
        this.nextEventIndex = 0;
        this.length = this.data.events.length;

        this.initializeTable();

        this.$play = $("#event-play");
        this.$pause = $("#event-pause");
        this.$replay = $("#event-replay");

        this.registerClickEvents();

        this.$pause.hide();
        this.$replay.hide();
    };

    Animation.prototype = {
        
        start: function() {
            this.isPaused = false;
            this.$play.hide();
            this.$pause.show();
            this.animateUpcomingEvents();
        },

        pause: function() {
            this.isPaused = true;
            this.$pause.hide();
            this.$play.show();
        },

        replay: function() {
            this.reset();
            this.$replay.hide();
            this.start();
        },

        reset: function() {
            this.nextEventIndex = 0;
            chart.series[0].update({
                data: this.data.initial
            });
            chart.series[0].redraw();
        },

        initializeTable: function() {
            this.eventTable = []; 
            var tbody = $("#event-table").find("tbody")
            for (var k = 0, length = this.data.new_count; k < length; k++) {
                var row = $("<tr>");
                var i = $("<td>").html(k).addClass('event-table-index'); 
                var j = $("<td>").addClass('event-table-index'); 
                var d = $("<td>").addClass('event-table-time'); 
                var r = $("<td>").addClass('event-table-time'); 
                var e = $("<td>").addClass('event-table-time'); 
                row.append(i).append(j).append(d).append(r).append(e);
                tbody.append(row); 
                this.eventTable.push({
                    i: i,
                    j: j,
                    d: d,
                    r: r,
                    e: e,
                    row: row
                });
            }
            window.tbody = tbody;
        },

        round: function(x) {
            return Math.round(x * 10000) / 10000;
        },

        showEventInfo: function(e) {
            var row = this.eventTable[e.i - data.stable_count];

            error = this.round(100 * Math.abs(e.rtt - e.d) / e.rtt);
            if (!error) {
                debugger;
            }
            row.j.html(e.j); 
            row.d.html(this.round(e.d)); 
            row.r.html(this.round(e.rtt)); 
            row.e.html(error); 

            for(var i = 0, length = this.data.new_count; i < length; i++) {
                var r = this.eventTable[i];
                if (r == row) {
                    r.row.addClass('event-table-row-active');
                }
                else {
                    r.row.removeClass('event-table-row-active');
                }
            }

        },

        registerClickEvents: function() {
            var self = this;
            this.$play.click(function() {
                self.start();
            });
            this.$pause.click(function() {
                self.pause();
            });
        },

        animateUpcomingEvents: function() {

            var self = this;

            var animateNextEvent = function() {
                if (self.isPaused) {
                    return;
                }
                if (self.nextEventIndex < self.length) {
                    var e = self.data.events[self.nextEventIndex++]
                    self.showEventInfo(e);
                    self.animateEvent(e);
                    setTimeout(animateNextEvent, 130);
                }
                else {
                    self.$pause.hide();
                    self.$replay.show();
                }
            }
            animateNextEvent();
        },

        animateEvent: function(e) {
            if(this.point_i) {
                this.point_i.update({
                    marker: {
                        fillColor: '#ff7043',
                        radius: 4
                    }
                })
            }
            if(this.point_j) {
                this.point_j.update({
                    marker: {
                        fillColor: '#4982b9',
                        radius: 4
                    }
                })
            }

            this.point_i = chart.series[0].data[e.i];
            this.point_j = chart.series[0].data[e.j];

            this.point_j.update({
                marker: {
                    fillColor: '#3f51b5',
                    radius: 5
                }
            })

            var x_i = e['x_i'];
            this.point_i.update({
                x: x_i[0],
                y: x_i[1],
                z: x_i[2],
                marker: {
                    fillColor: '#f44336',
                    radius: 5
                }
            }, true, {
                duration: 120,
                easing: 'ease-out'
            });
            
        }
    }; 

    Animation.prototype.constructor = Animation; 

    window.a = new Animation(data);

    // Give the points a 3D feel by adding a radial gradient
    Highcharts.getOptions().colors = $.map(Highcharts.getOptions().colors, function (color) {
        return {
            radialGradient: {
                cx: 0.1,
                cy: 0.1,
                r: 0.1
            },
            stops: [
                [0, color],
                [1, Highcharts.Color(color).brighten(-0.2).get('rgb')]
            ]
        };
    });

    // Set up the chart
    var chart = new Highcharts.Chart({
        chart: {
            renderTo: 'container',
            margin: 100,
            type: 'scatter',
            options3d: {
                enabled: true,
                alpha: 10,
                beta: 30,
                depth: 250,
                viewDistance: 5,
                fitToPlot: false,
                frame: {
                    bottom: { size: 1, color: 'rgba(0,0,0,0.02)' },
                    back: { size: 1, color: 'rgba(0,0,0,0.04)' },
                    side: { size: 1, color: 'rgba(0,0,0,0.06)' }
                }
            }
        },
        title: {
            text: 'Draggable box'
        },
        subtitle: {
            text: 'Click and drag the plot area to rotate in space'
        },
        plotOptions: {
            scatter: {
                width: 2,
                height: 2,
                depth: 2
            }
        },
        yAxis: {
            min: data.y_min * 1.1,
            max: data.y_max * 1.1,
            title: null
        },
        xAxis: {
            min: data.x_min * 1.1,
            max: data.y_max * 1.1,
            gridLineWidth: 1
        },
        zAxis: {
            min: data.z_min,
            max: data.z_max + 1,
            showFirstLabel: false
        },
        legend: {
            enabled: false
        },
        series: [{
            name: 'Coordinates',
            colorByPoint: false,
            data: data.initial
        }]
    });


    // Add mouse events for rotation
    $(chart.container).on('mousedown.hc touchstart.hc', function (eStart) {
        eStart = chart.pointer.normalize(eStart);

        var posX = eStart.pageX,
            posY = eStart.pageY,
            alpha = chart.options.chart.options3d.alpha,
            beta = chart.options.chart.options3d.beta,
            newAlpha,
            newBeta,
            sensitivity = 5; // lower is more sensitive

        $(document).on({
            'mousemove.hc touchdrag.hc': function (e) {
                // Run beta
                newBeta = beta + (posX - e.pageX) / sensitivity;
                chart.options.chart.options3d.beta = newBeta;

                // Run alpha
                newAlpha = alpha + (e.pageY - posY) / sensitivity;
                chart.options.chart.options3d.alpha = newAlpha;

                chart.redraw(false);
            },
            'mouseup touchend': function () {
                $(document).off('.hc');
            }
        });
    });

    window.chart = chart; 

});
