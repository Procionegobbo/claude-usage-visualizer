import Observation

@Observable
@MainActor
final class AppViewModel {
    var dataState: DataState = .loading
}
