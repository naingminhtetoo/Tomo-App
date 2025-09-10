import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { IonicModule } from '@ionic/angular';

import { FlashcardDeckPageRoutingModule } from './flashcard-deck-routing.module';

import { FlashcardDeckPage } from './flashcard-deck.page';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    IonicModule,
    FlashcardDeckPageRoutingModule
  ],
  // declarations: [FlashcardDeckPage]
})
export class FlashcardDeckPageModule {}
