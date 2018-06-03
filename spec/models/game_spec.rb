require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game_for_user! new correct game' do
      generate_questions(60)

      game = nil
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(
        change(GameQuestion, :count).by(15)
      )

      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  # тесты на основную игровую логику
  context 'game mechanics' do
    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it 'take money! finish the game' do
      # Берём игру и отвечаем на текущий вопрос
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)

      # Забираем деньги
      game_w_questions.take_money!

      # Проверяем приз
      prize = game_w_questions.prize
      expect(prize).to be > 0

      # Проверяем, корректно ли завершилась игра?
      expect(game_w_questions.status).to eq :money
      expect(game_w_questions.finished?).to be_truthy

      # И пришли деньги игроку
      expect(user.balance).to eq prize
    end
  end

  # тесты на статусы
  context '.status' do
    # Перед каждым следующим тестом завершаем игру
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it '.fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it '.timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it '.won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it '.money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end
end
