const canvas = document.querySelector('canvas')
const c = canvas.getContext('2d');

canvas.width = 1024;
canvas.height = 576;

const scaledCanvas = {
    width: canvas.width / 3,
    height: canvas.height / 3
}


// Declare a collision for path based on blocks
const pathCollisions2D = [];
for(let i = 0; i < pathCollisions.length; i += 36) {
    pathCollisions2D.push(pathCollisions.slice(i, i + 36));
}

const collisionBlocks = [];
pathCollisions2D.forEach((row, y) => {
    row.forEach((symbol, x) => {
        if(symbol === 3028) {
            collisionBlocks.push(
                new CollisionBlocks({
                    position: {
                        x: x * 16,
                        y: y * 16,
                    },
                })
            )
        }
    })
})

// Declare a collision for platform based of blocks
const platformCollisions2D = [];
for(let i = 0; i < platformCollisions.length; i += 36) {
    platformCollisions2D.push(platformCollisions.slice(i, i + 36));
}

const platformCollisionBlocks = [];
platformCollisions2D.forEach((row, y) => {
    row.forEach((symbol, x) => {
        if(symbol === 3028) {
            platformCollisionBlocks.push(
                new CollisionBlocks({
                    position: {
                        x: x * 16,
                        y: y * 16,
                    },
                })
            )
        }
    })
})


// Declare Gravity
const gravity = 0.2;

// Declare a characters
const player = new Player({
    position: {
        x: 200,
        y: 300,
    },
    collisionBlocks,
    platformCollisionBlocks,
    imageSrc: './img/warrior/_IdleRight.png',
    frameRate: 10,
    animations: {
        Idle: {
            imageSrc: './img/warrior/_IdleRight.png',
            frameRate: 10,
            frameBuffer: 4,
        },
        IdleLeft: {
            imageSrc: './img/warrior/_IdleLeft.png',
            frameRate: 10,
            frameBuffer: 4,
        },
        Run: {
            imageSrc: './img/warrior/_RunRight.png',
            frameRate: 10,
            frameBuffer: 4
        },
        RunLeft: {
            imageSrc: './img/warrior/_RunLeft.png',
            frameRate: 10,
            frameBuffer: 4 
        },
        Jump: {
            imageSrc: './img/warrior/_JumpRight.png',
            frameRate: 3,
            frameBuffer: 1
        },
        JumpLeft: {
            imageSrc: './img/warrior/_JumpLeft.png',
            frameRate: 3,
            frameBuffer: 1
        },
        Fall: {
            imageSrc: './img/warrior/_FallRight.png',
            frameRate: 3,
            frameBuffer: 1 
        },
        FallLeft: {
            imageSrc: './img/warrior/_FallLeft.png',
            frameRate: 3,
            frameBuffer: 1 
        },
    }
});


// Horizontal movement keys
const keys = {
    d: {
        pressed: false,
    },
    a: {
        pressed: false,
    }
}

// Declare a background
const background = new Sprite({
    position: {
        x: 0,
        y: 0
    },
    imageSrc: './img/background/HeroPlatformer.png',
})

// Declare a camera position based on the character
const camera = {
    position: {
        x: 0,
        y: -background.image.height + scaledCanvas.height,
    },
}

function animate() {
    window.requestAnimationFrame(animate);
    c.fillStyle = 'white';
    c.fillRect(0, 0, canvas.width, canvas.height);

    c.save();
    c.scale(3, 3);
    c.translate(camera.position.x, camera.position.y)
    background.update();

    // //Draws out each of collision blocks
    // collisionBlocks.forEach(collisionBlock => {
    //     collisionBlock.update();
    // });
    // platformCollisionBlocks.forEach(platformCollisionBlock => {
    //     platformCollisionBlock.update();
    // })

    player.horizontalCanvasCollision();
    player.update();

    player.velocity.x = 0;

    // Horizontal Movement
    if (keys.d.pressed) {
        player.switchSprite('Run');
        player.velocity.x = 2;
        player.lastDirection = 'right';
        player.panCameraToLeft({camera});
    } else if (keys.a.pressed) {
        player.switchSprite('RunLeft');
        player.velocity.x = -2;
        player.lastDirection = 'left';
        player.panCameraToRight({camera});
    } else if (player.velocity.y === 0) {
        if (player.lastDirection === 'right') {
            player.switchSprite('Idle');
        } else {
            player.switchSprite('IdleLeft');
        }
    }

    //Vertical Movement
    if (player.velocity.y < 0) {
        player.panCameraDown({camera});
        if (player.lastDirection === 'right') {
            player.switchSprite('Jump');
        } else {
            player.switchSprite('JumpLeft')
        }

    } else if (player.velocity.y > 0) {
        player.panCameraUp({camera});
        if (player.lastDirection === "right") {
            player.switchSprite('Fall');
        } else {
            player.switchSprite('FallLeft')
        }
    }
    c.restore();

}

animate();

// Controller
window.addEventListener('keydown', (event) => {
    switch(event.key) {
        case 'd':
            keys.d.pressed = true;
        break;
        case 'a':
            keys.a.pressed = true;
        break;
        case 'w':
            if (player.velocity.y == 0){
                player.velocity.y = -7
              }
        break;
    }
});

window.addEventListener('keyup', (event) => {
    switch(event.key) {
        case 'd':
            keys.d.pressed = false;
            break;
        case 'a':
            keys.a.pressed = false;
        break;
    }
});