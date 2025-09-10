import { Injectable, effect, signal, inject, Injector, runInInjectionContext } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom, timeout, catchError, of } from 'rxjs';
import { Preferences } from '@capacitor/preferences';
import { Network } from '@capacitor/network';
import { LevelStateService } from './level-state';

// Data structures remain the same
export interface VocabCard { word: string; reading: string; meaning: string; }
export interface VocabChapter { name: string; words: VocabCard[]; }
interface LevelData {
  level: string;
  kanji?: { chapters: VocabChapter[] };
  kanji_master?: { chapters: VocabChapter[] };
  adverbs?: { chapters: VocabChapter[] };
  vocab_shinkansen?: { chapters: VocabChapter[] };
  vocab_soumatome?: { chapters: VocabChapter[] };
  other?: { chapters: VocabChapter[] };
}

@Injectable({ providedIn: 'root' })
export class VocabularyService {
  private readonly DATA_BASE_URL = 'https://gist.githubusercontent.com/naingminhtetoo/aa317f1afb33303017bc78254b110198/raw/';

  private levelData = signal<LevelData | null>(null);
  public loadingState = signal<'loading' | 'ready' | 'error'>('ready');

  // We inject the Injector itself to control when dependencies are resolved.
  constructor(
    private http: HttpClient,
    private injector: Injector 
  ) {
    effect(() => {
      // This pattern breaks the circular dependency by resolving the service inside the effect's context.
      runInInjectionContext(this.injector, () => {
        const levelStateService = inject(LevelStateService); 
        const level = levelStateService.selectedLevel();
        if (level) {
          this.loadLevelData(level);
        }
      });
    });
  }

  public retryLoadData() {
    runInInjectionContext(this.injector, () => {
      const levelStateService = inject(LevelStateService);
      const currentLevel = levelStateService.selectedLevel();
      if (currentLevel) {
        this.loadLevelData(currentLevel);
      }
    });
  }
  
  private async loadLevelData(level: string) {
    this.loadingState.set('loading');
    const cacheKey = `level_data_${level}`;

    try {
      const networkStatus = await Network.getStatus();

      if (networkStatus.connected) {
        const remoteUrl = `${this.DATA_BASE_URL}${level}.json`;
        const remoteData$ = this.http.get<LevelData>(remoteUrl).pipe(
          timeout(8000),
          catchError(err => {
            console.error('HTTP request failed', err);
            return of(null);
          })
        );
        
        const remoteData = await firstValueFrom(remoteData$);

        if (remoteData) {
          await Preferences.set({ key: cacheKey, value: JSON.stringify(remoteData) });
          this.levelData.set(remoteData);
          console.log('Fetched remote data for level:', remoteData);
          this.loadingState.set('ready');
        } else {
          throw new Error('Failed to fetch remote data');
        }

      } else {
        const { value } = await Preferences.get({ key: cacheKey });
        if (value) {
          this.levelData.set(JSON.parse(value));
          this.loadingState.set('ready');
        } else {
          this.levelData.set(null);
          this.loadingState.set('error');
        }
      }
    } catch (error) {
      console.error(`Attempting to load from cache after error:`, error);
      try {
        const { value } = await Preferences.get({ key: cacheKey });
        if (value) {
          this.levelData.set(JSON.parse(value));
          this.loadingState.set('ready');
        } else {
          this.levelData.set(null);
          this.loadingState.set('error');
        }
      } catch (cacheError) {
        console.error(`All data sources failed for level: ${level}`, cacheError);
        this.levelData.set(null);
        this.loadingState.set('error');
      }
    }
  }
  
  // --- Public Methods to get data ---
  private getChapters = (type: 'kanji' | 'kanji_master' | 'adverbs' | 'vocab_shinkansen' | 'vocab_soumatome' | 'other') => this.levelData()?.[type]?.chapters || [];
  
  getKanjiChapterNames = () => this.getChapters('kanji').map(c => c.name);
  getAllKanjiWords = () => this.getChapters('kanji').flatMap(c => c.words);
  getKanjiWordsByChapter = (name: string) => this.getChapters('kanji').find(c => c.name === name)?.words || [];
  
  getKanjiMasterChapterNames = () => this.getChapters('kanji_master').map(c => c.name);
  getAllKanjiMasterWords = () => this.getChapters('kanji_master').flatMap(c => c.words);
  getKanjiMasterWordsByChapter = (name: string) => this.getChapters('kanji_master').find(c => c.name === name)?.words || [];

  getAllAdverbWords = () => this.getChapters('adverbs').flatMap(c => c.words);

  getVocabShinkansenChapterNames = () => this.getChapters('vocab_shinkansen').map(c => c.name);
  getAllVocabShinkansenWords = () => this.getChapters('vocab_shinkansen').flatMap(c => c.words);
  getVocabShinkansenWordsByChapter = (name: string) => this.getChapters('vocab_shinkansen').find(c => c.name === name)?.words || [];

  getVocabSoumatomeChapterNames = () => this.getChapters('vocab_soumatome').map(c => c.name);
  getAllVocabSoumatomeWords = () => this.getChapters('vocab_soumatome').flatMap(c => c.words);
  getVocabSoumatomeWordsByChapter = (name: string) => this.getChapters('vocab_soumatome').find(c => c.name === name)?.words || [];

  getOtherChapterNames = () => this.getChapters('other').map(c => c.name);
  getAllOtherWords = () => this.getChapters('other').flatMap(c => c.words);
  getOtherWordsByChapter = (name: string) => this.getChapters('other').find(c => c.name === name)?.words || [];
}
