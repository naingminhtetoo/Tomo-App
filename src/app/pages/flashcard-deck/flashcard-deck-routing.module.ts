import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { FlashcardDeckPage } from './flashcard-deck.page';

const routes: Routes = [
  {
    path: '',
    component: FlashcardDeckPage
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class FlashcardDeckPageRoutingModule {}
