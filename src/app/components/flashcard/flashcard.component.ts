import { Component, Input, Output, EventEmitter, ChangeDetectionStrategy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule } from '@ionic/angular';
import { VocabCard } from 'src/app/services/vocabulary';

@Component({
  selector: 'app-flashcard',
  templateUrl: './flashcard.component.html',
  styleUrls: ['./flashcard.component.scss'],
  standalone: true,
  imports: [CommonModule, IonicModule],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FlashcardComponent {
  // --- INPUTS: Data passed from the parent page ---
  @Input() card: VocabCard | null = null;
  @Input() isFlipped: boolean = false;

  // --- OUTPUT: Event emitted to the parent page ---
  @Output() cardClicked = new EventEmitter<void>();

  /**
   * Emits an event when the card is clicked.
   * The parent page will handle the flip logic.
   */
  onCardClick() {
    this.cardClicked.emit();
  }
}
