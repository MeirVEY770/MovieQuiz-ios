import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!

    private var currentQuestionIndex = 0
    private var correctAnswers = 0
    private let questionsAmount: Int = 10
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var statisticService: StatisticService = StatisticServiceImplementation()
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        yesButton.isEnabled = false
        noButton.isEnabled = false
        questionFactory = QuestionFactory()
        questionFactory?.delegate = self
        questionFactory?.requestNextQuestion()
    }
    
    // MARK: - QuestionFactoryDelegate

    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
            self?.yesButton.isEnabled = true
            self?.noButton.isEnabled = true
        }
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        yesButton.isEnabled = false
        noButton.isEnabled = false
        if isCorrect {
            correctAnswers += 1
        }
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    private func resetQuiz() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }

    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        if currentQuestionIndex == questionsAmount - 1 {
            let bestGame = statisticService.bestGame
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yy HH:mm"
            
            var bestGameText = "Рекорд: Нет данных"
            if let bestGame = bestGame {
                bestGameText = "Рекорд: \(bestGame.correct)/\(bestGame.total) (\(dateFormatter.string(from: bestGame.date)))"
            }
            
            let averageAccuracy = statisticService.totalAccuracy * 100
            
            let alertText = """
                Ваш результат: \(correctAnswers)/\(questionsAmount)
                Количество сыгранных квизов: \(statisticService.gamesCount)
                \(bestGameText)
                Средняя точность: \(String(format: "%.2f", averageAccuracy))%
                """
            
            let alertModel = AlertModel(
                title: "Этот раунд окончен!",
                message: alertText,
                buttonText: "Сыграть ещё раз") { [weak self] in
                self?.resetQuiz()
            }
            
            AlertPresenter.presentAlert(with: alertModel, in: self)
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let alert = UIAlertController(
            title: result.title,
            message: result.text,
            preferredStyle: .alert)
        
        let action = UIAlertAction(title: result.buttonText, style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        }
        
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
}
