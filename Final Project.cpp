// This file owns: dice rolling, bet math, win/lose/push classification.

#include <cstdlib>
#include <ctime>

extern "C" {

    // Implemented in callme.asm. Drives the whole program once seeded.
    void RunGame();

    // Roll two dice (1-6 each), write results through the pointers.
    void rollDice(int* die1Out, int* die2Out) {
        *die1Out = (std::rand() % 6) + 1;
        *die2Out = (std::rand() % 6) + 1;
    }

    // Apply the spec's betting rule using the player's chosen bet amount.
    int applyBet(int balance, int total, int bet) {
        if (total == 7 || total == 11) {
            return balance + bet;
        }
        if (total == 2 || total == 3 || total == 12) {
            return balance - bet;
        }
        return balance;
    }

    // 1 = win (7/11), 2 = lose (2/3/12), 3 = push (anything else).
    int classifyRoll(int total) {
        if (total == 7 || total == 11) {
            return 1;
        }
        if (total == 2 || total == 3 || total == 12) {
            return 2;
        }
        return 3;
    }

}

int main() {
    std::srand(static_cast<unsigned>(std::time(nullptr)));
    RunGame();
    return 0;
}
