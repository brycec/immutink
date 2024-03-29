        var stage;
        var isMouseDown;
        var currentShape;
        var oldMidX, oldMidY, oldX, oldY;
        var txt;

        function init() {
        	if (window.top != window) {
        		document.getElementById("header").style.display = "none";
        	}

            txt = new createjs.Text("Click and Drag to Draw", "36px Arial", "#777777");
            txt.x = 300;
            txt.y = 200;
            stage = new createjs.Stage("myCanvas");
            stage.autoClear = true;
            stage.onMouseDown = handleMouseDown;
            stage.onMouseUp = handleMouseUp;

			createjs.Touch.enable(stage);

            stage.addChild(txt);
            stage.update();
			createjs.Ticker.addListener(window);
        }

        function stop() {
			createjs.Ticker.removeListener(window);
        }

        function tick() {
            if (isMouseDown) {
                var pt = new createjs.Point(stage.mouseX, stage.mouseY);
                var midPoint = new createjs.Point(oldX + pt.x>>1, oldY+pt.y>>1);
                currentShape.graphics.moveTo(midPoint.x, midPoint.y);
                currentShape.graphics.curveTo(oldX, oldY, oldMidX, oldMidY);

                oldX = pt.x;
                oldY = pt.y;

                oldMidX = midPoint.x;
                oldMidY = midPoint.y;

                stage.update();
            }
        }

        function handleMouseDown() {
            isMouseDown = true;
            stage.removeChild(txt);

            var s = new createjs.Shape();
            oldX = stage.mouseX;
            oldY = stage.mouseY;
            oldMidX = stage.mouseX;
            oldMidY = stage.mouseY;
            var g = s.graphics;
            var thickness = Math.random() * 30 + 10 | 0;
            g.setStrokeStyle(thickness + 1, 'round', 'round');
            var color = createjs.Graphics.getRGB(Math.random()*255 | 0 ,Math.random()*255 | 0, Math.random()*255 | 0);
            g.beginStroke(color);
            stage.addChild(s);
            currentShape = s;
        }

        function handleMouseUp() {
            isMouseDown = false;
        }
/*
<body onload="init();">

    <header id="header" class="EaselJS">
        <h1><span class="text-product">Easel<strong>JS</strong></span> CurveTo</h1>
        <p>This example demonstrates painting to the canvas using the vector drawing API in EaselJS</p>
    </header>

    <canvas id="myCanvas" width="960" height="400"></canvas>
</body>
</html>
*/