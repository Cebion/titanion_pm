/*
 * $Id: pad.d,v 1.1.1.1 2006/11/19 07:54:55 kenta Exp $
 *
 * Copyright 2006 Kenta Cho. Some rights reserved.
 */
module abagames.util.sdl.pad;

private import std.string;
private import std.conv;
private import std.stdio;
private import bindbc.sdl;
private import abagames.util.sdl.input;
private import abagames.util.sdl.recordableinput;

version(PANDORA) version = PANDORA_OR_PYRA;
version(PYRA) version = PANDORA_OR_PYRA;

/**
 * Inputs from a joystick and a keyboard.
 */
public class Pad: Input {
 public:
  ubyte *keys;
  bool buttonsExchanged = false;
 private:
  SDL_Joystick *stick = null;
  const int JOYSTICK_AXIS = 16384;
  PadState state;

  public this() {
    state = new PadState;
  }

  public SDL_Joystick* openJoystick(SDL_Joystick *st = null) {
    return null; // Disable joystick because of sdl_joystickopen
  }

  public void handleEvents() {
    keys = SDL_GetKeyboardState(null);
  }

  public PadState getState() {
    int x = 0, y = 0;
    state.dir = 0;
    if (stick) {
      x = SDL_JoystickGetAxis(stick, 0);
      y = SDL_JoystickGetAxis(stick, 1);
    }
    if (keys[SDL_SCANCODE_RIGHT] == SDL_PRESSED || keys[SDL_SCANCODE_KP_6] == SDL_PRESSED ||
        keys[SDL_SCANCODE_D] == SDL_PRESSED || keys[SDL_SCANCODE_L] == SDL_PRESSED ||
        x > JOYSTICK_AXIS)
      state.dir |= PadState.Dir.RIGHT;
    if (keys[SDL_SCANCODE_LEFT] == SDL_PRESSED || keys[SDL_SCANCODE_KP_4] == SDL_PRESSED ||
        keys[SDL_SCANCODE_A] == SDL_PRESSED || keys[SDL_SCANCODE_J] == SDL_PRESSED ||
        x < -JOYSTICK_AXIS)
      state.dir |= PadState.Dir.LEFT;
    if (keys[SDL_SCANCODE_DOWN] == SDL_PRESSED || keys[SDL_SCANCODE_KP_2] == SDL_PRESSED ||
        keys[SDL_SCANCODE_S] == SDL_PRESSED || keys[SDL_SCANCODE_K] == SDL_PRESSED ||
        y > JOYSTICK_AXIS)
      state.dir |= PadState.Dir.DOWN;
    if (keys[SDL_SCANCODE_UP] == SDL_PRESSED ||  keys[SDL_SCANCODE_KP_8] == SDL_PRESSED ||
        keys[SDL_SCANCODE_W] == SDL_PRESSED || keys[SDL_SCANCODE_I] == SDL_PRESSED ||
        y < -JOYSTICK_AXIS)
      state.dir |= PadState.Dir.UP;
    state.button = 0;
    bool btnx = false, btnz = false;
    int btn1 = 0, btn2 = 0;
    float leftTrigger = 0, rightTrigger = 0;
    version(PYRA) {
    } else {
      if (stick) {
        btn1 = SDL_JoystickGetButton(stick, 0) + SDL_JoystickGetButton(stick, 2) +
               SDL_JoystickGetButton(stick, 4) + SDL_JoystickGetButton(stick, 6) +
               SDL_JoystickGetButton(stick, 8) + SDL_JoystickGetButton(stick, 10);
        btn2 = SDL_JoystickGetButton(stick, 1) + SDL_JoystickGetButton(stick, 3) +
               SDL_JoystickGetButton(stick, 5) + SDL_JoystickGetButton(stick, 7) +
               SDL_JoystickGetButton(stick, 9) + SDL_JoystickGetButton(stick, 11);
      }
    }
    version (PANDORA_OR_PYRA) {
      if (keys[SDL_SCANCODE_HOME] == SDL_PRESSED || keys[SDL_SCANCODE_PAGEUP] == SDL_PRESSED) btnz = true;
      if (keys[SDL_SCANCODE_PAGEDOWN] == SDL_PRESSED || keys[SDL_SCANCODE_END] == SDL_PRESSED) btnx = true;
    } else {
      if (keys[SDL_SCANCODE_Z] == SDL_PRESSED || keys[SDL_SCANCODE_PERIOD] == SDL_PRESSED ||
          keys[SDL_SCANCODE_LCTRL] == SDL_PRESSED || keys[SDL_SCANCODE_RCTRL] == SDL_PRESSED ||
          btn1) btnz = true;
      if (keys[SDL_SCANCODE_X] == SDL_PRESSED || keys[SDL_SCANCODE_SLASH] == SDL_PRESSED ||
          keys[SDL_SCANCODE_LALT] == SDL_PRESSED || keys[SDL_SCANCODE_RALT] == SDL_PRESSED ||
          keys[SDL_SCANCODE_LSHIFT] == SDL_PRESSED || keys[SDL_SCANCODE_RSHIFT] == SDL_PRESSED ||
          keys[SDL_SCANCODE_RETURN] == SDL_PRESSED ||
          btn2) btnx = true;
    }
    if (btnz) {
      if (!buttonsExchanged)
        state.button |= PadState.Button.A;
      else
        state.button |= PadState.Button.B;
    }
    if (btnx) {
      if (!buttonsExchanged)
        state.button |= PadState.Button.B;
      else
        state.button |= PadState.Button.A;
    }
    return state;
  }

  public PadState getNullState() {
    state.clear();
    return state;
  }

}

public class PadState {
 public:
  static enum Dir {
    UP = 1, DOWN = 2, LEFT = 4, RIGHT = 8,
  };
  static enum Button {
    A = 16, B = 32, ANY = 48,
  };
  int dir, button;
 private:

  public static PadState newInstance() {
    return new PadState;
  }

  public static PadState newInstance(PadState s) {
    return new PadState(s);
  }

  public this() {
  }

  public this(PadState s) {
    this();
    set(s);
  }

  public void set(PadState s) {
    dir = s.dir;
    button = s.button;
  }

  public void clear() {
    dir = button = 0;
  }

  public void read(File fd) {
    int[1] read_data;
    fd.rawRead(read_data);
    dir = read_data[0] & (Dir.UP | Dir.DOWN | Dir.LEFT | Dir.RIGHT);
    button = read_data[0] & Button.ANY;
  }

  public void write(File fd) {
    int[1] write_data = [dir | button];
    fd.rawWrite(write_data);
  }

  public bool equals(PadState s) {
    if (dir == s.dir && button == s.button)
      return true;
    else
      return false;
  }
}

public class RecordablePad: Pad {
  mixin RecordableInput!(PadState);
 private:

  public override PadState getState() {
    return getState(true);
  }

  public PadState getState(bool doRecord) {
    PadState s = super.getState();
    if (doRecord)
      record(s);
    return s;
  }
}
