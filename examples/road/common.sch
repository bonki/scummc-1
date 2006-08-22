/* ScummC
 * Copyright (C) 2006  Alban Bedel
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 */

// include all the vars used by the engine itself
#include <scummVars6.s>

verb Give,  PickUp, Use;
verb Open,  LookAt, Push;
verb Close, TalkTo, Pull;
verb WalkTo, WalkToXY;
verb SntcLine;
verb invSlot0 @ 100, invSlot1 @ 101, invSlot2 @ 102, invSlot3 @ 103,
    invSlot4 @ 104, invSlot5 @ 105, invSlot6 @ 106, invSlot7 @ 107;

// callbacks
verb Icon,Preposition,SetBoxes;


// define an actor for our hero
actor  hero;

class Openable,Pickable;

bit verbsOn,cursorOn,cursorLoaded;

int sntcVerb,sntcObjA,sntcObjB;
char *sntcPrepo;
int selVerb,altVerb;
int tryPick;
int* invObj;

bit welcomed,lost;

room Road {
    object leftDoor;
    object axe;
    object river;
}

room ResRoom {

    // define the charset we are going to use
    // the gui use the first charset, so te be sure force its address
    chset chset1 @ 1 = "vera-gui.char";
    // our standard charset
    chset chtest = "vera.char";
    // and the costume for our actor
    cost egoCost = "devil.cost";

    // an object for the cursor image
    object cursor {
        x = 0;
        y = 0;
        w = 16;
        h = 16;
        name = "cursor";
        states = {
            { 3, 3, "cursor.bmp" }
        };
    }

    // the inventory icons
    object axe {
        w = 40;
        h = 16;
        x = 0;
        name = "the axe";
        states = {
            { 0, 0, "inv_axe.bmp" }
        };
        state = 1;
    }

    local script localTest() {
        dbgPrint("Ltst");
    }

    // some startup scripts

    // set the actor costume, etc
    script setupActors() {
        // create the actor
        setCurrentActor(hero);
        initActor();
        setActorCostume(egoCost);
        setActorTalkPos(-60,-60);
        setActorName("Beasty");
        setActorWalkSpeed(2,1);
        setActorTalkColor(0xC6);
        setActorWidth(40);
        setActorAnimSpeed(2);
        // set VAR_EGO so we can use the *Ego* functions
        VAR_EGO = hero;
    }

    // setup all the verbs
    script setupVerbs() {
        int color,hiColor,dimColor,l,c,vrb;

        color = 0x36;
        hiColor = 0x37;
        dimColor = 26;

        sntcVerb = WalkTo;
        //sntcObjA = 0;
        //sntcObjB = 0;

        setCurrentVerb(SntcLine);
        initVerb();
        setVerbName("%v{sntcVerb} %n{sntcObjA} %s{sntcPrepo} %n{sntcObjB}");
        setVerbXY(160,146);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        verbCenter();

        setCurrentVerb(WalkTo);
        initVerb();
        setVerbName("Walk to");
        setVerbKey('w');

        setCurrentVerb(Give);
        initVerb();
        setVerbName("Give");
        setVerbXY(10,156);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('g');
        
        setCurrentVerb(PickUp);
        initVerb();
        setVerbName("Pick up");
        setVerbXY(50,156);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('p');

        setCurrentVerb(Use);
        initVerb();
        setVerbName("Use");
        setVerbXY(100,156);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('u');

        setCurrentVerb(Open);
        initVerb();
        setVerbName("Open");
        setVerbXY(10,170);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('o');

        setCurrentVerb(LookAt);
        initVerb();
        setVerbName("Look at");
        setVerbXY(50,170);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('l');

        setCurrentVerb(Push);
        initVerb();
        setVerbName("Push");
        setVerbXY(100,170);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        //setVerbKey('');

        setCurrentVerb(Close);
        initVerb();
        setVerbName("Close");
        setVerbXY(10,184);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('c');

        setCurrentVerb(TalkTo);
        initVerb();
        setVerbName("Talk to");
        setVerbXY(50,184);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        setVerbKey('t');

        setCurrentVerb(Pull);
        initVerb();
        setVerbName("Pull");
        setVerbXY(100,184);
        setVerbColor(color);
        setVerbHiColor(hiColor);
        setVerbDimColor(dimColor);
        //setVerbKey('');

        for(l = 0,vrb = invSlot0 ; l < 2 ; l++)
            for(c = 0 ; c < 4 ; c++, vrb++) {
                setCurrentVerb(vrb);
                initVerb();
                //verbCenter();
                setVerbXY(160 + c*40,160 + l*20);
            }
        dimInt(invObj,8);

    }

    // turn on all the verb for the interface 
    // and fire the mouse watching thread
    script showVerbs() {
        int* vrb;
        int i;
       
        if(verbsOn) return;
 
        vrb[0] = [ Give, PickUp, Use, Open, LookAt, Push, Close, TalkTo, Pull,
                   SntcLine ];
        
        for(i = 0 ; i < 10 ; i++) {
            setCurrentVerb(vrb[i]);
            setVerbOn();
            redrawVerb();
        }
        undim(vrb);

        for(i = 0 ; i < 8 ; i++) {
            setCurrentVerb(invSlot0+i);
            setVerbOn();
            redrawVerb();
        }

        verbsOn = 1;

    }


    // this script run in the background cheking where the mouse is
    // and update the sentence and set the alt verb
    script mouseWatch() {
        int vrb,obj,target,alt;

        // we run forever (well until someone kill us)
        while(1) {
            unless(cursorOn) {
                if(altVerb) {
                    setCurrentVerb(altVerb);
                    setVerbOn();
                    redrawVerb();
                    altVerb = 0;
                }
                do breakScript() until(cursorOn);
                        
            }
            if(isScriptRunning(VAR_SENTENCE_SCRIPT)) {
                 breakScript();
                continue;
            }

            // read the current state

            // find what verb should be displayed and the
            // object under the pointer
            vrb = 0;
            obj = getObjectAt(VAR_VIRT_MOUSE_X,VAR_VIRT_MOUSE_Y);
            unless(obj) {
                obj = getVerbAt(VAR_MOUSE_X,VAR_MOUSE_Y);
                if(obj >= invSlot0 && obj <= invSlot7) {
                    obj = findInventory(VAR_EGO,obj-invSlot0+1);
                    if(!selVerb || selVerb == PickUp)
                        vrb = Use;
                    else
                        vrb = selVerb;
                } else
                    obj = 0;
            }
            unless(vrb)
                vrb = selVerb ? selVerb : WalkTo;                    
            
            if(sntcPrepo) {
                target = sntcObjB;
                if(obj == sntcObjA) obj = 0;
            } else target = sntcObjA;
            
            //dbgPrint("%i{vrb} <> %i{sntcVerb} | %i{obj} <> %i{target}");
            unless(vrb == sntcVerb && obj == target) {
                sntcVerb = vrb;
                if(sntcPrepo) sntcObjB = obj;
                else sntcObjA = obj;
                setCurrentVerb(SntcLine);
                redrawVerb();
            }


            if(obj) {
                if(isObjectOfClass(obj, [ Openable + 0x80 ]))
                    alt = getObjectState(obj) ? Close : Open;
                else
                    alt = LookAt;
            } else
                alt = 0;

            if(alt != altVerb) {
                if(altVerb) {
                    setCurrentVerb(altVerb);
                    setVerbOn();
                    redrawVerb();
                }
                if(alt) {
                    setCurrentVerb(alt);
                    verbDim();
                    redrawVerb();
                }
                altVerb = alt;
            }

            breakScript();
        }
    }


    // setup the cursor
    script showCursor() {
        
        if(cursorOn) return;
/*
        unless(cursorLoaded) {
            cursorLoaded = 1;
            loadFlObject(cursor,ResRoom);
            setCursorImage(cursor,ResRoom);
            setCursorTransparency(31);
        }
*/
        cursorOn();
        userPutOn();
        cursorOn = 1;
    }

    script hideCursor() {
        unless(cursorOn) return;
        
        cursorOff();
        userPutOff();
        cursorOn = 0;
    }

    script cutsceneStart(int type) {
        dbgPrint("cutscene start");
        hideCursor();
    }

    script cutsceneEnd(int type) {
        dbgPrint("cutscene end");
        showCursor();
    }

    script resetSntc(int vrb) {
        sntcObjA = 0;
        if(sntcPrepo) {
            undim(sntcPrepo);
            sntcObjB = 0;
        }
        selVerb = vrb;
        setCurrentVerb(SntcLine);
        redrawVerb();
    }

    script defaultAction(int vrb, int objA, int objB) {
        switch(vrb) {
        case WalkTo:
            return;
            
        case PickUp:
            egoSay("I can't pick that up.");
            break;
            
        case Use:
            egoSay("I can't use that !.");
            break;
            
        case LookAt:
            egoSay("There is nothing special about it.");
            break;
            
        case Push:
        case Pull:
            egoSay("I don't feel in shape today.");
            break;
            
        case Open:
            if(isObjectOfClass(objA,[Openable])) {
                egoSay("It's not the kind of thing that can be opened.");
                break;
            }
            if(getObjectState(objA)) {
                egoSay("It's already open.");
                break;
            }
            // some sound would be nice
            setObjectState(objA,1);
            if(getObjectVerbEntrypoint(objA,SetBoxes))
                startObject2(objA,SetBoxes, [ vrb, objA ]);
            break;
            
        case Close:
            if(isObjectOfClass(objA,[Openable])) {
                egoSay("I don't think that this can be closed.");
                break;
            }
            unless(getObjectState(objA)) {
                egoSay("It's already closed.");
                break;
            }
            setObjectState(objA,0);
            if(getObjectVerbEntrypoint(objA,SetBoxes))
                startObject2(objA,SetBoxes, [ vrb, objA ]);
            break;
                
        default:
            egoSay("Hmm. No.");
            break;
        }
        waitForMessage();
    }

    // the sentence script, doSentence call it
    script sentenceHandler(int vrb, int objA, int objB) {
        int owner,tmp;

        // click on the sentence line, make it as if the user
        // clicked the currently selected objects
        if(vrb == SntcLine) {
            vrb = sntcVerb;
            objA = sntcObjA;
            objB = sntcObjB;
        }

        // look who own the object
        owner = getObjectOwner(objA);

        // with use and give we must own it first
        while(isAnyOf(vrb, [ Use, Give ])) {
            unless(objB) {
                if(getObjectVerbEntrypoint(objA,Preposition)) {
                    startObject2(objA,Preposition,[ vrb, objA ]);
                    if(sntcPrepo) {
                        setCurrentVerb(SntcLine);
                        redrawVerb();
                        return;
                    }
                }
                break;
            }

            // we must pick it up first
            if(owner != VAR_EGO) {
                if(tryPick == objA) { // pickup failed
                    tryPick = 0;
                    return;
                }
                // try to pickup then do our action again
                tryPick = objA;
                doSentence(vrb,objA,0,objB);
                doSentence(PickUp,objA,0,0);
                return;
            } else
                tryPick = 0;
            break;
        }
        
        // if the object is in the room walk there
        if(owner == 0xF) {
            walkActorToObj(VAR_EGO,objA,0);
            waitForActor(VAR_EGO);
        } else if(objB) if(getObjectOwner(objB) == 0xF) {
            walkActorToObj(VAR_EGO,objB,0);
            waitForActor(VAR_EGO);
        }

        // switch the objects
        if(objB) {
            dbgPrint("Switch objects");
            tmp = objA;
            objA = objB;
            objB = tmp;
        }

        // if the object implement the verb call that
        if(getObjectVerbEntrypoint(objA,vrb)) {
            startObject(2,objA,vrb,[ vrb, objA, objB ]);
            // if the verb locked the cursor wait until its unlocked
            do breakScript() until(cursorOn);
        } else {
            //otherwise use our default:
            defaultAction(vrb, objA, objB);
 
        }
        // if the verb need objB we are done for now
        if(sntcPrepo && !objB) return;

        // all done, reset the sentence
        resetSntc(0);
    }


    // This script receive the keyboard and mouse events
    script inputHandler(int area,int cmd, int btn) {
        int vrb,obj,objB,x;

        dbgPrintBegin();
        dbgPrint("Area=%i{area} cmd=%i{cmd} button=%i{btn}");
        dbgPrintEnd();

        egoPrintBegin();
        egoPrintOverhead();
        actorPrintEnd();

        if(area == 4) { // area 4 is the keyboard
            switch(cmd) {
            case 'o':
                egoSay("Hooo");
                break;
            case 'r':
                egoSay("Let's restart.");
                waitForMessage();
                restartGame();
                break;
            case 'q':
                shutdown();
                break;
            case '1':
                animateActor(Road::leftDoor,250);
            }
            return;
        }

        // A verb was clicked
        if(isAnyOf(cmd, [ Give,  PickUp, Use, 
                          Open,  LookAt, Push,
                          Close, TalkTo, Pull ])) {
            resetSntc(cmd);
            return;
        }

        // now are left: room click and inventory
        // stop any currently running sentence
        stopSentence();
        // (re)start the mouse script, giving it a chance to update
        // the sentence.
        // Note that it's a non recursive call hence it will kill the script
        // then start it again.
        mouseWatch();

        // button 2 was cliked but not on an object: cancel
        if(btn == 2) unless(sntcPrepo ? sntcObjB : sntcObjA) {
            // stop walking
            setCurrentActor(VAR_EGO);
            setActorStanding();
            resetSntc(0);
            return;
        }

        // an object was cliked
        if(sntcPrepo ? sntcObjB : sntcObjA) {
            // an inventory object was cliked
            // select the verb that is displayed
            // We need this to keep Use when PickUp
            // was originaly selected
            if(cmd) selVerb = sntcVerb;
            // button 2: select the alternat verb
            if(btn == 2 && altVerb) {
                selVerb = altVerb;
                mouseWatch();
            }
            // queue the sentence
            doSentence(sntcVerb,sntcObjA,0,sntcObjB);
            return;
        }
        // click on nothing, ignore non room clicks
        if(area != 2) return;

        // reset the sentence so we get WalkTo again
        if(selVerb) resetSntc(0);
        
        // then go there
        walkActorTo(VAR_EGO,VAR_VIRT_MOUSE_X,VAR_VIRT_MOUSE_Y);
    }

    script setInventoryIcon(int icon, int slot) {
        setCurrentVerb(slot);
        setVerbObject(icon,ResRoom);
        redrawVerb();
    }

    script inventoryHandler(int obj) {
        int i, count;
        //unless(obj) return;

        count = getInventoryCount(hero);

        dbgPrint("%i{count} obj in inv");


        for(i = 0 ; i < 8 ; i++) {
            if(i < count) {
                obj = findInventory(hero,i+1);
                startObject2(obj,Icon, [ setInventoryIcon, invSlot0+i ]);
            } else {
                setCurrentVerb(invSlot0+i);
                setVerbNameString(0);
                redrawVerb();
            }
        }

    }

    // The main script is the first thing started by the engine.
    // At that point no room is loaded yet.
    script main (int bootParam) {
        int i,j;

        //trace(1,"main");
        // First setup the engine a bit
        // set the F5 key for the main menu
        VAR_MAINMENU_KEY = 319;
        // set the . key to skip text
        VAR_TALKSTOP_KEY = 46;
        // set F8 as the restart key
        VAR_RESTART_KEY = 322;
        // pause key can also be defined in that way instead of
        // doing it in the key handler as we did.
        VAR_PAUSE_KEY = ' ';
        // skip a cutscene
        VAR_CUTSCENEEXIT_KEY = 27;

        VAR_GAME_VERSION = 0;
        VAR_GUI_COLORS[0] = [ 0x00, 0x00, 0x43, 0x00, 0xD7, 0x34, 0x52, 0x90, 0x00, 0x6A,
                              0x06, 0x1A, 0xD5, 0xE5, 0xE3, 0xE5, 0xE3, 0xE5, 0xE3, 0xE5,
                              0xE3, 0x00, 0x00, 0x00, 0x00, 0x14, 0xD7, 0xE5, 0xE3, 0xE5,
                              0xE3, 0x37, 0x1C, 0xE5, 0xE3, 0xE5, 0xE3, 0x14, 0xD7, 0xE5,
                              0xE3, 0xE5, 0xE3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 ];
//                     0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6, 0xC6 ];



        VAR_DEBUG_PASSWORD[0] = "";
        //VAR_DEBUG_PASSWORD[0] = "pass";
        //for(i = 0 ; VAR_DEBUG_PASSWORD[i] != 0 ; i++)
        //    VAR_DEBUG_PASSWORD[i] = VAR_DEBUG_PASSWORD[i] - 'c';
      

        // setup the GUI
        VAR_PAUSE_MSG[0] = "ScummC Paused !";
        VAR_QUIT_MSG[0] = "Are you sure you want to quit ? (Y/N)Y";
        VAR_RESTART_MSG[0] = "Are you sure you want to restart ? (Y/N)Y";

        VAR_SAVE_BTN[0] = "Save it";
        VAR_LOAD_BTN[0] = "Load it";
        VAR_PLAY_BTN[0] = "Continue";
        VAR_CANCEL_BTN[0] = "Cancel";
        VAR_QUIT_BTN[0] = "Quit";
        VAR_OK_BTN[0] = "Ok";

        VAR_SAVE_MSG[0] = "Saveing '%%s'";
        VAR_LOAD_MSG[0] = "Loading '%%s'";

        VAR_MAIN_MENU_TITLE[0] = "ScummC test Menu";
        VAR_SAVE_MENU_TITLE[0] = "Save game";
        VAR_LOAD_MENU_TITLE[0] = "Load game";

        VAR_NOT_SAVED_MSG[0] = "Game NOT saved";
        VAR_NOT_LOADED_MSG[0] = "Game NOT loaded";

        VAR_GAME_DISK_MSG[0] = "Insert disk %%c";
        VAR_ENTER_NAME_MSG[0] = "You must enter a name";
        VAR_SAVE_DISK_MSG[0] = "Insert your save disk";

        VAR_OPEN_FAILED_MSG[0] = "Failed to open %%s (%%c%%d)";
        VAR_READ_ERROR_MSG[0] = "Read error on disk %%c (%%c%%d)";

        // set the main loop speed
        VAR_TIMER_NEXT = 2;
        
        // set the input handler
        VAR_VERB_SCRIPT = inputHandler;
        VAR_SENTENCE_SCRIPT = sentenceHandler;
        VAR_INVENTORY_SCRIPT = inventoryHandler;
        VAR_CUTSCENE_START_SCRIPT = cutsceneStart;
        VAR_CUTSCENE_END_SCRIPT = cutsceneEnd;

        // keep this room in memory even if we leave it,
        // as it contain the charset, costume, etc
        // it's probably not very useful atm bcs we only have one
        // room, but well :)
        loadRoom(ResRoom);
        lockRoom(ResRoom);

        loadCostume(egoCost);
        lockCostume(egoCost);

        loadRoom(Road);
        lockRoom(Road);

        // Initialize the graphic mode.
        // It need to match the room image height otherwise
        // the graphics are going wacky
        setScreen(0,144);
        //setScreen(44,188);

        // init the charset
        //initCharset(chset1);
        initCharset(chtest);


        setupActors();
        setupVerbs();

        mouseWatch();

        // do the box effect
        screenEffect(0x0005);
        // start the room
        startRoom(Road);
    }

}


// our room
room Road {
    // first we define the room parameters
    // the background picture
    image = "road.bmp";
    // the zplanes
    zplane = { "road_mask1.bmp", "road_mask2.bmp" };

    boxd = "road.box";
    trans = 0;

    //cycle testCycl = { 60, 0, 103, 111 };

    voice letsgothere = { "letsgothere.voc", 500 };
    voice welcome = { "welcome.voc" };
    voice tv = { "file.voc" };

    object axe;

    object leftDoor {
        x = 152;
        y = 35;
        dir = NORTH;
        name = "the door";
        class = { Openable };
        states = { 
            { 8, 40, "door_left.bmp", { "", "" } }
        };
        state = 0;

        verb(int vrb,int objA, int objB) {
        case SetBoxes:
            if(vrb == Open)
                setBoxFlags( [ openDoor ], 0x80);
            else
                setBoxFlags( [ openDoor ], 0);
            createBoxMatrix();
            return;

        case WalkTo:
            if(getObjectState(objA))
                egoSay("Even open, this door is way too small for me.");
            else
                egoSay("It's closed.");
            return;

        case Use:
            if(objB) {
                if(objB == axe)
                    egoSay("I don't want to destroy this door.");
                else
                    egoSay("That doesn't make much sense.");
                return;
            }
            if(getObjectState(objA))
                doSentence(Close,objA,0,0);
            else
                doSentence(Open,objA,0,0);
        }
    }

    object window {
        x = 112;
        y = 46;
        w = 32;
        h = 16;
        hs_x = 16;
        hs_y = 30;
        dir = NORTH;
        name = "the window";
    }

    object river {
        x = 0;
        y = 0;
        w = 48;
        h = 20;
        hs_x = 33;
        hs_y = 15;
        dir = WEST;
        name = "the river";

        verb(int vrb,int objA, int objB) {
        case LookAt:
            cutscene() {
                egoSay("Wa _ Water ??\wI hate that stuff.");
                waitForMessage();
            }

        case Use:
            if(objB == axe)
                egoSay("A axe is not that great to fish.");
            else
                egoSay("Don't even think about it.");
            return;
        
        case PickUp:
            egoSay("I need something to put the water in.");
            return;
        }
    }

    object axe {
        x = 320;
        y = 27;
        w = 16;
        h = 8;
        class = { Pickable };
        states = {
            { 0, 16, "axe.bmp",
              { "", "axe_mask2.bmp" } }
        };
        name = "the axe";
        dir = EAST;

        
        verb(int vrb,int objA,int objB) {
        case Icon:
            startScript2(vrb, [ ResRoom::axe, objA, objB ]);
            return;
        case Preposition:
            if(vrb == Give)
                sntcPrepo[0] = "to";
            else
                sntcPrepo[0] = "on";
            return;

        case LookAt:
            if(getObjectOwner(objA) == VAR_EGO)
                egoSay("It's really sharp.");
            else
                egoSay("Look nice !");
            return;

        case PickUp:
            egoSay("Cool");
            pickupObject(objA,VAR_ROOM);
        }
    }

    local script walkOut(int eff) {
        screenEffect(eff);
        startRoom(Road);
    }

    object exitSouth {
        x = 0;
        y = 128;
        w = 108;
        h = 16;
        hs_x = 50;
        hs_y = 4;
        name = "the road going out";
        dir = SOUTH;

        verb(int vrb, int objA, int objB) {
        case WalkTo:
        case Use:
            walkOut(0x8787);
        }

    }

    object exitEast {
        x = 472;
        y = 72;
        w = 16;
        h = 48;
        hs_x = 5;
        hs_y = 24;
        name = "the road going out";
        dir = EAST;

        verb(int vrb, int objA, int objB) {
        case WalkTo:
        case Use:
            walkOut(0x8686);
        }

    }

    object exitNorth {
        x = 410;
        y = 0;
        w = 72;
        h = 16;
        hs_x = 36;
        hs_y = 8;
        name = "the road going out";
        dir = NORTH;

        verb(int vrb, int objA, int objB) {
        case WalkTo:
        case Use:
            walkOut(0x8080);
        }

    }

    local script localTest() {
        dbgPrint("T2st");
    }

    // This script is executed when the room is loaded
    local script entry() {

        dbgPrintBegin();
        dbgPrint("Entry");
        dbgPrintEnd();

        // our palette is buggy, fix it
        setRoomColor(0,0,0,0);

        // init the print slot
        egoPrintBegin();
        actorPrintOverhead();
        actorPrintEnd();
        

        unless(welcomed) {
            putActorAt(VAR_EGO,440,0,Road);
            try {
                setCameraAt(0);
                panCameraTo(440);
                waitForCamera();
                cameraFollowActor(VAR_EGO);
                walkActorTo(hero,430,80);
                waitForActor(hero);
                
                egoSay("Hello mortal.");
                waitForMessage();
                egoSay("Welcome to the first GPL Scumm game !!!");
                waitForMessage();
            } override {
                if(VAR_OVERRIDE) {
                    setCameraAt(440);
                    putActorAt(VAR_EGO,430,80,Road);
                    cameraFollowActor(VAR_EGO);
                }
            }
            welcomed = 1;
        } else {
     
            switch(getRandomNumber(2)) {
            case 0:
                putActorAt(VAR_EGO,488,90,Road);
                setCurrentActor(VAR_EGO);
                setActorDirection(WEST);
                cameraFollowActor(VAR_EGO);
                walkActorTo(hero,420,90);
                break;
            case 1:
                putActorAt(VAR_EGO,460,0,Road);
                cameraFollowActor(VAR_EGO);
                walkActorTo(hero,450,40);
                break;
            case 2:
                putActorAt(VAR_EGO,60,144,Road);
                setCurrentActor(VAR_EGO);
                setActorDirection(NORTH);
                cameraFollowActor(VAR_EGO);
                walkActorTo(hero,80,120);
                break;
            }

            unless(lost) {
                waitForActor(hero);
                egoSay("I think I'm lost.");
                lost = 1;
            }
        }

        ResRoom::showVerbs();
        ResRoom::showCursor();

        localTest();

    }

    local script exit() {
        dbgPrintBegin();
        dbgPrint("Exit");
        dbgPrintEnd();

        ResRoom::hideCursor();
    }


}
