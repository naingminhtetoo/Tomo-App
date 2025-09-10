import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'level-select', // Change the default route to the new page
    pathMatch: 'full'
  },
  {
    path: 'home',
    loadChildren: () => import('./home/home.module').then( m => m.HomePageModule)
  },
  // Update the routes to point to the new common page
  {
    path: 'deck/:type', // The ':type' is a URL parameter
    loadComponent: () => import('./pages/flashcard-deck/flashcard-deck.page').then(m => m.FlashcardDeckPage)
  },
  // {
  //   path: 'kanji',
  //   loadComponent: () => import('./pages/kanji/kanji.page').then(m => m.KanjiPage)
  // },
  // {
  //   path: 'kanji-master',
  //   loadComponent: () => import('./pages/kanji-master/kanji-master.page').then(m => m.KanjiMasterPage)
  // },
  // {
  //   path: 'adverb',
  //   loadChildren: () => import('./pages/adverb/adverb.module').then( m => m.AdverbPageModule)
  // },
  // Add the route for the new level-select page
  {
    path: 'level-select',
    loadChildren: () => import('./pages/level-select/level-select.module').then( m => m.LevelSelectPageModule)
  },
  {
    path: 'flashcard-deck',
    loadChildren: () => import('./pages/flashcard-deck/flashcard-deck.module').then( m => m.FlashcardDeckPageModule)
  },
];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule {}

