import { NgModule } from '@angular/core';
import { Routes, RouterModule } from '@angular/router';

import { LevelSelectPage } from './level-select.page';

const routes: Routes = [
  {
    path: '',
    component: LevelSelectPage
  }
];

@NgModule({
  imports: [RouterModule.forChild(routes)],
  exports: [RouterModule],
})
export class LevelSelectPageRoutingModule {}
