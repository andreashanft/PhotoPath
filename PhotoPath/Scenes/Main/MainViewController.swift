//
//  ViewController.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    private let mainCellId = "MainViewController.cell"
    
    @IBOutlet weak var debugOutputOverlay: UIView!
    @IBOutlet weak var debugOutput: UITextView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var startContainer: UIView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var startActivityContainer: UIView!
    @IBOutlet weak var startActivityLabel: UILabel!

    var viewModel: MainViewModel!
    
    private var stopButton: UIBarButtonItem?
    private var clearButton: UIBarButtonItem?
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debugOutputOverlay.isHidden = true
        debugOutputOverlay.alpha = 0
        debugOutput.text = ""
        
        tableView.delegate = self
        tableView.dataSource = self
        
        startActivityLabel.text = "Warming up GPS...".localised()
        
        let stopButton = UIBarButtonItem(title: "Stop".localised(), style: .done, target: self, action: #selector(stopButtonTapped))
        navigationItem.rightBarButtonItem = stopButton
        self.stopButton = stopButton
        
        let clearButton = UIBarButtonItem(title: "Clear".localised(), style: .done, target: self, action: #selector(clearButtonTapped))
        self.clearButton = clearButton
        
        viewModel.onDataChanged = { [weak self] data in
            guard data.count > 0, let self = self else { return }
            
            self.setActivePhotoStreamState()
            self.tableView.reloadData()
        }
        
        viewModel.onError = { [weak self] in
            self?.showError()
        }
        
        DebugLogger.onOutputChange = { [weak self] output in
            self?.debugOutput.text = output.reversed().joined(separator: "\n")
        }
        
        if viewModel.isMonitoringActive {
            setActivePhotoStreamState()
        } else {
            setDefaultState()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startContainer.layer.cornerRadius = startContainer.frame.width / 2
    }
    
    // MARK: - Interface State
    
    private func setDefaultState() {
        stopButton?.isEnabled = false
        navigationItem.leftBarButtonItem = nil
        startButton.isHidden = false
        startContainer.isHidden = false
        startActivityContainer.isHidden = true
        tableView.isHidden = true
    }
    
    private func setLookingForLocationState() {
        startButton.isHidden = true
        stopButton?.isEnabled = true
        startActivityContainer.isHidden = false
    }
    
    private func setActivePhotoStreamState() {
        guard viewModel.isMonitoringActive else { return }
        
        startContainer.isHidden = true
        tableView.isHidden = false
        
        tableView.reloadData()
    }
    
    private func setFinishedPhotoStreamState() {
        stopButton?.isEnabled = false
        navigationItem.leftBarButtonItem = clearButton
        startContainer.isHidden = true
        tableView.isHidden = false
    }
    
    private func showError() {
        let alert = UIAlertController(
            title: "Error".localised(),
            message: "Could not record your path. Please check your location service settings and always allow this app to use your location.".localised(),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Maybe later".localised(), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings".localised(), style: .default, handler: { _ in
            // Open the settings app
            if let url = NSURL(string: UIApplication.openSettingsURLString) as URL? {
                UIApplication.shared.open(url)
            }
        }))
        present(alert, animated: true) { [weak self] in
            self?.viewModel.onStopButtonTapped()
            self?.setDefaultState()
        }
    }
    
    // MARK: - Interface Actions
    
    @IBAction func startButtonTapped(_ sender: Any) {
        setLookingForLocationState()
        viewModel.onStartButtonTapped()
    }
    
    @IBAction func closeDebugOverlayButtonTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.2, animations: {
            self.debugOutputOverlay.alpha = 0
        }) { _ in
            self.debugOutputOverlay.isHidden = true
        }
    }
    
    @IBAction func copyTrackButtonTapped(_ sender: Any) {
        viewModel.onCopyTrackButtonTapped()
    }
    
    @objc func stopButtonTapped() {
        viewModel.onStopButtonTapped()
        setFinishedPhotoStreamState()
    }
    
    @objc func clearButtonTapped() {
        setDefaultState()
    }
    
    /// Shake device to open debug view
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super .motionEnded(motion, with: event)
        
        guard motion == .motionShake, debugOutputOverlay.isHidden else { return }
        
        self.debugOutputOverlay.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.debugOutputOverlay.alpha = 1
        }
    }
}

// MARK: - UITableViewDataSource

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.numberOfItems
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: mainCellId, for: indexPath)
        
        guard
            let mainCell = cell as? MainTableViewCell,
            let presentation = viewModel.item(for: indexPath.row)
        else {
            return cell
        }
        
        mainCell.configure(with: presentation)
        
        return mainCell
    }
}

// MARK: - UITableViewDelegate

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return nil
    }
}
