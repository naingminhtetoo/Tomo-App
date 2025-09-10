import { ChangeDetectionStrategy, Component, signal, effect, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IonicModule, AlertController } from '@ionic/angular';
import { ActivatedRoute } from '@angular/router'; // Import ActivatedRoute
import { ToggleChangeEventDetail, SelectChangeEventDetail } from '@ionic/core';
import { VocabCard, VocabularyService } from 'src/app/services/vocabulary';
import { FlashcardComponent } from 'src/app/components/flashcard/flashcard.component';

// Define the types of decks our page can handle
type DeckType = 'kanji' | 'kanji_master' | 'adverb' | 'vocab_shinkansen' | 'vocab_soumatome' | 'other';

@Component({
  selector: 'app-flashcard-deck',
  templateUrl: './flashcard-deck.page.html',
  styleUrls: ['./flashcard-deck.page.scss'],
  standalone: true,
  imports: [CommonModule, IonicModule, FlashcardComponent],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FlashcardDeckPage {
  private alertController = inject(AlertController);
  public vocabService = inject(VocabularyService);
  private route = inject(ActivatedRoute); // Inject ActivatedRoute

  // Page state
  public pageTitle = signal('');
  public pageSubtitle = signal('');
  public deckType = signal<DeckType>('kanji');

  // Deck state
  shuffledCards: VocabCard[] = [];
  currentIndex = signal(0);
  currentCard = signal<VocabCard | null>(null);
  isFlipped = signal(false);
  shuffleEnabled = signal(false);
  chapters: string[] = [];
  selectedChapter = signal('all');

  constructor() {
    // Determine the deck type from the URL parameter
    const type = this.route.snapshot.paramMap.get('type') as DeckType;
    if (type) {
      this.deckType.set(type);
      this.setupPageInfo(type);
    }

    effect(() => {
      if (this.vocabService.loadingState() === 'ready') {
        this.initializePage();
      }
    });
  }

  // Set the page title and subtitle based on the deck type
  private setupPageInfo(type: DeckType) {
    if (type === 'kanji') {
      this.pageTitle.set('漢字（総まとめ）');
      this.pageSubtitle.set('Kanji Cards');
    } else if (type === 'kanji_master') {
      this.pageTitle.set('漢字　マスタ');
      this.pageSubtitle.set('Kanji Master Cards');
    } else if (type === 'adverb') {
      this.pageTitle.set('副詞カード');
      this.pageSubtitle.set('Adverb Cards');
    }
    else if (type === 'vocab_shinkansen') {
      this.pageTitle.set('語彙　新完全マスター');
      this.pageSubtitle.set('Vocabulary Cards');
    }
    else if (type === 'vocab_soumatome') {
      this.pageTitle.set('語彙　総まとめ');
      this.pageSubtitle.set('Vocabulary Cards');
    } 
    else if (type === 'other') {
      this.pageTitle.set('その他の単語');
      this.pageSubtitle.set('Other Useful Words');
    }
  }

  initializePage() {
    const type = this.deckType();
    if (type === 'kanji') {
      this.chapters = this.vocabService.getKanjiChapterNames();
    } else if (type === 'kanji_master') {
      this.chapters = this.vocabService.getKanjiMasterChapterNames();
    } else if (type === 'vocab_shinkansen') {
      this.chapters = this.vocabService.getVocabShinkansenChapterNames();
    }
    else if (type === 'vocab_soumatome') {
      this.chapters = this.vocabService.getVocabSoumatomeChapterNames();
    }
    else if (type === 'other') {
      this.chapters = this.vocabService.getOtherChapterNames();
    }
    // Adverb page does not have chapters, so the list will be empty

    this.resetDeck();
  }

  retry() {
    this.vocabService.retryLoadData();
  }

  resetDeck() {
    let deck: VocabCard[] = [];
    const type = this.deckType();
    const chapterName = this.selectedChapter();

    if (type === 'kanji') {
      deck = chapterName === 'all' ? this.vocabService.getAllKanjiWords() : this.vocabService.getKanjiWordsByChapter(chapterName);
    } else if (type === 'kanji_master') {
      deck = chapterName === 'all' ? this.vocabService.getAllKanjiMasterWords() : this.vocabService.getKanjiMasterWordsByChapter(chapterName);
    } else if (type === 'vocab_shinkansen') {
      deck = chapterName === 'all' ? this.vocabService.getAllVocabShinkansenWords() : this.vocabService.getVocabShinkansenWordsByChapter(chapterName);
    } else if (type === 'vocab_soumatome') {
      deck = chapterName === 'all' ? this.vocabService.getAllVocabSoumatomeWords() : this.vocabService.getVocabSoumatomeWordsByChapter(chapterName);
    } else if (type === 'other') {
      deck = chapterName === 'all' ? this.vocabService.getAllOtherWords() : this.vocabService.getOtherWordsByChapter(chapterName);
    }
    else if (type === 'adverb') {
      deck = this.vocabService.getAllAdverbWords();
    }

    if (this.shuffleEnabled()) {
      for (let i = deck.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [deck[i], deck[j]] = [deck[j], deck[i]];
      }
    }

    this.shuffledCards = deck;
    this.currentIndex.set(0);
    this.currentCard.set(this.shuffledCards.length > 0 ? this.shuffledCards[0] : null);
    this.isFlipped.set(false);
  }

  // No changes needed for the methods below
  onChapterChange(event: CustomEvent<SelectChangeEventDetail>) {
    this.selectedChapter.set(event.detail.value);
    this.resetDeck();
  }

  async onShuffleToggle(event: CustomEvent<ToggleChangeEventDetail>) {
    const shouldShuffle = event.detail.checked;
    const toggleElement = event.target as HTMLIonToggleElement;

    if (this.currentIndex() === 0) {
      this.shuffleEnabled.set(shouldShuffle);
      this.resetDeck();
      return;
    }

    const alert = await this.alertController.create({
      header: 'Restart Session?',
      message: 'Changing this setting will restart the current process from the beginning.',
      cssClass: 'custom-alert',
      buttons: [
        { text: 'Cancel', role: 'cancel', cssClass: 'alert-button-cancel', handler: () => { toggleElement.checked = !shouldShuffle; } },
        { text: 'Confirm', cssClass: 'alert-button-confirm', handler: () => { this.shuffleEnabled.set(shouldShuffle); this.resetDeck(); } },
      ],
    });
    await alert.present();
  }

  showNextCard() {
    const nextIndex = this.currentIndex() + 1;
    if (nextIndex < this.shuffledCards.length) {
      this.currentIndex.set(nextIndex);
      this.currentCard.set(this.shuffledCards[nextIndex]);
    }
  }

  showPreviousCard() {
    const prevIndex = this.currentIndex() - 1;
    if (prevIndex >= 0) {
      this.currentIndex.set(prevIndex);
      this.currentCard.set(this.shuffledCards[prevIndex]);
    }
  }

  flipCard() {
    this.isFlipped.update(value => !value);
  }
}
