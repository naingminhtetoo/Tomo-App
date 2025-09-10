import { NgModule } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';

import { IonicModule } from '@ionic/angular';

import { LevelSelectPageRoutingModule } from './level-select-routing.module';

import { LevelSelectPage } from './level-select.page';

@NgModule({
  imports: [
    CommonModule,
    FormsModule,
    IonicModule,
    LevelSelectPageRoutingModule
  ],
  // declarations: [LevelSelectPage]
})
export class LevelSelectPageModule {}
