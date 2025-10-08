import { version } from '../package.json'
import * as PIXI from 'pixi.js'
import Matter from 'matter-js'


console.log "App version #{version}"

BACK_WIDTH = 1920
BACK_HEIGHT = 1080
BACK_RATIO = BACK_WIDTH / BACK_HEIGHT

ICONS = [
    "bug-01",
    "bug-02",
    "fish-01",
    "fish-02",
    "fish-03",
    "insects-01",
    "insects-02",
    "сancer-01",
    "сancer-02",
    "сancer-03",
    "mollusks-01",
    "mollusks-02",
    "mollusks-03",
    "snail",
    "worm-01",
    "worm-02"
]

intToHex = (intColor) ->
    string = intColor.toString(16).padStart(6, '0')
    "##{string}"

randRange = (min, max) -> Math.random() * (max - min) + min

randIntRange = (min, max) -> Math.floor(randRange min, max)

windowSizes = ->
    ww = window.innerWidth
    wh = window.innerHeight
    [
        ww
        wh
        if wh then ww / wh else 1
    ]

class BoxBody

    @anchor = {
        x: 0
        y: 0
    }

    constructor: (x, y, width, height, color, isStatic=true, options=null) ->
        @display = new PIXI.Graphics()
        @display.x = x - BoxBody.anchor.x
        @display.y = y - BoxBody.anchor.y
        @width = width
        @height = height
        @color = color
        @display.rect -width / 2, -height / 2, width, height
        @display.fill color
        #display.stroke {
        #    width: 0
        #    color: borderColor
        #}
        @display.eventMode = 'static'
        @display.cursor = 'pointer'
        @options = {...(options or {}), ...{
            isStatic
            render: {
                fillStyle: intToHex color
            }
        }}
        @body = Matter.Bodies.rectangle x + width / 2, y + height / 2, width, height, @options

    move: ->
        { x, y } = @body.position
        @display.x = x
        @display.y = y
        @display.rotation = @body.angle


class SpriteBody

    constructor: (x, y, width, height, texture, isStatic=true, options=null) ->
        @display = PIXI.Sprite.from texture
        @display.anchor.set .5
        @display.x = x
        @display.y = y
        @display.width = width
        @display.height = height
        @display.eventMode = 'static'
        @display.cursor = 'pointer'
        @options = {...(options or {}), ...{
            isStatic
        }}
        @body = Matter.Bodies.rectangle x + width / 2, y + height / 2, width, height, @options

    move: ->
        { x, y } = @body.position
        @display.x = x
        @display.y = y
        @display.rotation = @body.angle


class Physics

    constructor: (containerId) ->
        @container = document.getElementById containerId
        @app = new PIXI.Application()
        @actors = []

    init: ->
        await @assetsLoad()
        await @app.init {
            antialias: true
            resizeTo: @container
            useBackBuffer: true
        }
        @container.appendChild @app.canvas
        window.addEventListener 'resize', @onResize.bind(@), false
        @app.ticker.add @tick, @
        @timer = window.setInterval @onTimer.bind(@), 1000
        @physicsInit()
        @createScene()
        @onResize()

    assetsLoad: ->
        resources = [{
            alias: 'background'
            src: 'assets/background.png'
        }]
        for alias in ICONS
            src = "assets/#{alias}.png"
            resources.push {
                alias
                src
            }
        PIXI.Assets.addBundle 'clicker', resources
        PIXI.Assets.backgroundLoadBundle ['clicker']
        await PIXI.Assets.loadBundle 'clicker'

    onResize: (e) ->
        @width = @app.screen.width
        @height = @app.screen.height
        [ww, wh, wr] = windowSizes()
        if wr > BACK_RATIO
            @background.width = ww
            @background.height = ww / BACK_RATIO
        else
            @background.width = wh * BACK_RATIO
            @background.height = wh

    tick: (time) ->
        @actors.forEach (a) ->
            a.move()
        if @engine
            Matter.Engine.update @engine, time.deltaTime * (1000 / 60)

    createScene: (name) ->
        @background = PIXI.Sprite.from 'background'
        @background.anchor.set .5
        @background.x = @app.screen.width * .5
        @background.y = @app.screen.height * .5
        @app.stage.addChild @background

        { screen, stage } = @app
        wall = 10000
        BoxBody.anchor = {
            x: @app.screen.width / 2
            y: @app.screen.height / 2
        }
        # top wall
        box = new BoxBody 0, -wall+1, screen.width, wall, 0xffffff
        @actors.push box
        # bottom wall
        box = new BoxBody 0, screen.height-3, screen.width, wall, 0xffffff
        @actors.push box
        # left wall
        box = new BoxBody -wall+1, 0, wall, screen.height, 0xffffff
        @actors.push box
        # right wall
        box = new BoxBody screen.width-1, 0, wall, screen.height, 0xffffff
        @actors.push box
        # red box
        box = new BoxBody 330, 40, 50, 50, 0x990000, false, {
            frictionAir: .02
            restitution: .75
        }
        @actors.push box
        # green box
        box = new BoxBody 350, 150, 50, 50, 0x009900, false, {
            friction: .00001
            frictionAir: .001
            restitution: .75
            density: .005
        }
        @actors.push box
        # sprites
        for alias in ICONS
            size = randIntRange 80, 100
            x = randIntRange size, @app.screen.width - size
            y = randIntRange size, @app.screen.height / 2
            sprite = new SpriteBody x, y, size, size, alias, false, {
                density: .0005
                frictionAir: .06
                restitution: .3
                friction: .01
            }
            @actors.push sprite
        self = @
        @actors.forEach (a) -> stage.addChild a.display
        Matter.Composite.add @engine.world, @actors.map (a) -> a.body

    physicsInit: ->
        @engine = Matter.Engine.create()
        @engine.gravity.y = .25
        mouse = Matter.Mouse.create @app.canvas
        mouseConstraint = Matter.MouseConstraint.create @engine, {
            mouse
            constraint: {
                stiffness: 0.2
                render: {
                    visible: false
                }
            }
        }
        Matter.Composite.add @engine.world, mouseConstraint

    onTimer: ->
        bodies = []
        for actor in @actors
            if Matter.Body.getSpeed(actor.body) < .01
                bodies.push actor.body
        if not bodies.length
            bodies.push @actors[randIntRange 0, @actors.length].body
        for body in bodies
            force = randRange .5, .75
            angle = randRange -Math.PI * .3, -Math.PI * .6
            Matter.Body.applyForce body, body.position, {
                x: Math.cos(angle) * force 
                y: Math.sin(angle) * force
            }


(() ->
    app = new Physics 'app-container'
    await app.init()
)()
