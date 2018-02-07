#!/usr/bin/env python3

# University of Verona - Languages 2017/2018
# Little parser for the MDT K project by JackHack96 aka Matteo Iervasi

import subprocess
import sys
import os
import xml.etree.ElementTree

krun_path = "/opt/k/bin/krun"


class Colors:
    ENDC = '\033[0m'
    CYAN_BOLD = '\033[1;36m'
    YELLOW_BOLD = '\033[1;33m'
    CYAN_BACK_BOLD = '\033[1;46;33m'
    GREEN_BOLD = '\033[1;92m'
    RED_BOLD = '\033[1;31m'


def print_section(s):
    print("======================================================================")
    print(Colors.RED_BOLD + s + Colors.ENDC)


def print_tape(tape, show_current_position=False, current_position=0):
    if show_current_position:
        for t in sorted(tape):
            if t != current_position:
                print("    ", end='')
            else:
                print(Colors.GREEN_BOLD + "  v " + Colors.ENDC, end='')
        print("")
    for _ in tape:
        print("+---", end='')
    print("+")
    for t in sorted(tape):
        if t != current_position or show_current_position is False:
            print("| " + Colors.YELLOW_BOLD + str(tape[t]).replace("\"", "") + Colors.ENDC + " ", end='')
        elif show_current_position and t == current_position:
            print("|" + Colors.CYAN_BACK_BOLD + " " + str(tape[t]).replace("\"", "") + " " + Colors.ENDC, end='')
    print("|")
    for _ in tape:
        print("+---", end='')
    print("+")
    for t in sorted(tape):
        if 0 <= t < 10:
            print("  " + Colors.CYAN_BOLD + str(t) + Colors.ENDC + " ", end='')
        elif t < 0:
            print(" " + Colors.CYAN_BOLD + str(t) + Colors.ENDC + " ", end='')
        else:
            print("  " + Colors.CYAN_BOLD + str(t) + Colors.ENDC, end='')
    print("")
    if show_current_position:
        for t in sorted(tape):
            if t != current_position:
                print("    ", end='')
            else:
                print(Colors.GREEN_BOLD + "  ^ " + Colors.ENDC, end='')
        print("")


if __name__ == '__main__' and os.path.exists(krun_path):
    if len(sys.argv) == 2 and os.path.exists(sys.argv[1]):
        # First load the initial tape
        with open(sys.argv[1]) as f:
            content = f.readlines()
        initial_tape = {}
        for l in content:
            if l.startswith("\""):
                for s in l.split(","):
                    initial_tape[len(initial_tape)] = s.strip().replace("\"", "")

        # Run KRun
        stdout, stderr = subprocess.Popen(krun_path + " " + sys.argv[1], stdout=subprocess.PIPE,
                                          shell=True).communicate()

        root = xml.etree.ElementTree.fromstring(stdout)

        # The K cell
        print_section("K:")
        print(root[0].text)

        # Parse the resulting tape
        print_section("Initial tape:")
        print_tape(initial_tape)
        print_section("Final tape:")
        tape = {}
        for t in str(root[1].text).strip().replace(" |-> ", "|->").split(" "):
            tape[int(t.split("|->")[0])] = t.split("|->")[1]
        print_tape(tape, show_current_position=True, current_position=int(root[3].text))

        # Current state
        print_section("Current state:")
        print(root[2].text)

        # Current position
        print_section("Current position:")
        print(root[3].text)

        # Transitions
        print_section("Transitions:")
        transitions = {}
        for t in str(root[4].text).strip().replace(" |-> ", "|->").replace(") (", ")  (").replace(" ,", ",").split(
                "  "):
            transitions[t.split("|->")[0]] = t.split("|->")[1]
        for t in sorted(transitions):
            print(t + " |-> " + transitions[t])

        # States
        print_section("States:")
        print(str(root[5].text).strip().replace(") S", ")\nS"))

        # Final state
        print_section("Final state:")
        print(str(root[6].text).strip())

        # Initial state
        print_section("Initial state:")
        print(str(root[7].text).strip())
    else:
        print("Error, please launch this script with the K file to be executed as argument!")
        sys.exit(1)
else:
    print("Please specify your krun binary location in the krun_path variable")
