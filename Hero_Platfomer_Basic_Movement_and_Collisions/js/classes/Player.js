class Player extends Sprite {
    constructor({
        position, 
        collisionBlocks, 
        platformCollisionBlocks, 
        imageSrc, 
        frameRate, 
        scale = 1, 
        animations
    }) {
        super({
            imageSrc,
            frameRate, 
            scale
        });
        this.position = position;
        this.velocity = {
            x: 0,
            y: 1,
        };
        this.collisionBlocks = collisionBlocks;
        this.platformCollisionBlocks = platformCollisionBlocks;
        this.hitbox = {
            position: {
                x: this.position.x,
                y: this.position.y
            },
            width: 10,
            height: 10,
        };
        this.animations = animations;
        this.lastDirection = 'right';

        for(let key in this.animations) {
            const image = new Image();
            image.src = this.animations[key].imageSrc
            this.animations[key].image = image;
        }

        this.camerabox = {
            position: {
                x: this.position.x,
                y: this.position.y,
            },
            width: 200,
            height: 115,
        }
    }

    switchSprite(key) {
        if(this.image === this.animations[key].image || !this.loaded) {
            return;
        }
        this.currentFrame = 0;
        this.image = this.animations[key].image;
        this.frameBuffer = this.animations[key].frameBuffer;
        this.frameRate = this.animations[key].frameRate;
    }

    horizontalCanvasCollision() {
        if (this.hitbox.position.x + this.hitbox.width + this.velocity.x >= canvas.height ||
            this.hitbox.position.x + this.velocity.x <= 0) {
            this.velocity.x = 0;
        }
    }

    panCameraToLeft({camera}) {
        const cameraboxRightSide = this.camerabox.position.x + this.camerabox.width;
        if( cameraboxRightSide > canvas.height) {
            return
        }

        if(cameraboxRightSide >= scaledCanvas.width + Math.abs(camera.position.x)) {
            camera.position.x -= this.velocity.x;
        }
    }

    panCameraToRight({camera}) {
        const cameraboxLeftSide = this.camerabox.position.x;
        if( cameraboxLeftSide <= 0) {
            return
        }

        if(cameraboxLeftSide <= Math.abs(camera.position.x)) {
            camera.position.x -= this.velocity.x;
        }
    }

    panCameraDown({camera}) {
        const cameraboxDownSide = this.camerabox.position.y;
        if( cameraboxDownSide + this.velocity.y <= 0) {
            return
        }

        if(cameraboxDownSide <= Math.abs(camera.position.y)) {
            camera.position.y -= this.velocity.y;
        }
    }

    panCameraUp({camera}) {
        const cameraboxUpSide = this.camerabox.position.y + this.camerabox.height;
        if (cameraboxUpSide + this.velocity.y >= canvas.height) {
            return
        }

        if (cameraboxUpSide >= Math.abs(camera.position.y) + scaledCanvas.height) {
            camera.position.y -= this.velocity.y;
        }
    }

    update() {
        this.updateFrames();
        this.updateHitbox();
        this.updateCamerabox();

        // Draws out the camerabox
        // c.fillStyle = 'rgba(0, 0, 255, 0.2)';
        // c.fillRect(
        //     this.camerabox.position.x, 
        //     this.camerabox.position.y, 
        //     this.camerabox.width, 
        //     this.camerabox.height
        // );

        // Draws out the image
        // c.fillStyle = 'rgba(0, 255, 0, 0.2)';
        // c.fillRect(this.position.x, this.position.y, this.width, this.height);
        
        // c.fillStyle = 'rgba(255, 0, 0, 0.2)';
        // c.fillRect(
        //     this.hitbox.position.x, 
        //     this.hitbox.position.y, 
        //     this.hitbox.width, 
        //     this.hitbox.height
        // );
            
            this.draw();

            this.position.x += this.velocity.x;
            this.updateHitbox();    
            this.horizontalCollisions();
            this.applyGravity();
            this.updateHitbox();
            this.verticalCollisions();
    }

    updateCamerabox() {
        this.camerabox = {
            position: {
                x: this.position.x - 40,
                y: this.position.y,
            },
            width: 200,
            height: 113,
        }

    }
    
    updateHitbox() {
        this.hitbox = {
            position: {
                x: this.position.x + 55,
                y: this.position.y + 40
            },
            width: 20,
            height: 40,
        };
    }

    horizontalCollisions() {
        for(let i = 0; i < this.collisionBlocks.length; i++) {
            const collisionBlock = this.collisionBlocks[i];
            if (
                collision({
                    object1: this.hitbox,
                    object2: collisionBlock
                })
            ) {
                if (this.velocity.x > 0) {
                    this.velocity.x = 0;

                    const offset = this.hitbox.position.x - this.position.x + this.hitbox.width;

                    this.position.x = collisionBlock.position.x - offset - 0.01;
                    break;
                }

                if (this.velocity.x < 0) {
                    this.velocity.x = 0;

                    const offset = this.hitbox.position.x - this.position.x;

                    this.position.x = collisionBlock.position.x + collisionBlock.width - offset + 0.01;
                    break;
                }
               }
        }
     }

    applyGravity() {
        this.velocity.y += gravity;
        this.position.y += this.velocity.y;
    }
    
    verticalCollisions() {
        // Path Collision Blocks
        for(let i = 0; i < this.collisionBlocks.length; i++) {
            const collisionBlock = this.collisionBlocks[i];
            if (
                collision({
                    object1: this.hitbox,
                    object2: collisionBlock
                })
            ) {
                if (this.velocity.y > 0) {
                    this.velocity.y = 0;

                    const offset = this.hitbox.position.y -this.position.y + this.hitbox.height

                    this.position.y = collisionBlock.position.y - offset - 0.01
                    break;
                }

                if (this.velocity.y < 0) {
                    this.velocity.y = 0;

                    const offset = this.hitbox.position.y - this.position.y;

                    this.position.y = collisionBlock.position.y + collisionBlock.height - offset + 0.01
                    break;
                }
               }
        }

        // Platform Collisionb Blocks
        for(let i = 0; i < this.platformCollisionBlocks.length; i++) {
            const platformCollisionBlock = this.platformCollisionBlocks[i];
            if (
                platformCollision({
                    object1: this.hitbox,
                    object2: platformCollisionBlock
                })
            ) {
                if (this.velocity.y > 0) {
                    this.velocity.y = 0;

                    const offset = this.hitbox.position.y -this.position.y + this.hitbox.height

                    this.position.y = platformCollisionBlock.position.y - offset - 0.01
                    break;
                }
               }
        }
     }
}