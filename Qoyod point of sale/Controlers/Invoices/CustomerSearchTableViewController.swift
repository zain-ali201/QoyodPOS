//
//  CustomerSearchTableViewController.swift
//  Qoyod point of sale
//
//  Created by Sharjeel Ahmad on 28/09/2018.
//  Copyright © 2018 Sharjeel Ahmad. All rights reserved.
//

import UIKit

class CustomerSearchTableViewController: UITableViewController {
    
    fileprivate lazy var contacts:[Contact] = []
    fileprivate lazy var tableViewDatasource:[Contact] = []
    @IBOutlet weak var searchBar: UISearchBar!
    var searchTerm = ""
    var selectedContact:Contact!
    
    var refresher:UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refresher = UIRefreshControl()
        self.tableView.alwaysBounceVertical = true
        self.refresher.addTarget(self, action: #selector(loadData), for: .valueChanged)
       self.tableView.addSubview(refresher)

        self.clearsSelectionOnViewWillAppear = false
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        searchBar.becomeFirstResponder()
        
        if customersList.count == 0
        {
            loadData()
        }
        else
        {
            self.contacts = customersList
            self.tableViewDatasource = self.contacts
            self.tableView.reloadData()
        }
    }
    
    @objc func loadData()
    {
        CustomerManager.shared.getContacts {[weak self] (list, error) in
            if let list = list {
                self?.refresher.endRefreshing()
                self?.contacts = list
                customersList = list
                self?.tableViewDatasource = list
                self?.tableView.reloadData()
            }
        }
    }

    func refreshSource() {
        if searchTerm.isEmpty {
            tableViewDatasource = contacts
        }else {
            tableViewDatasource = contacts.filter { (obj) -> Bool in
                let customerName = obj.contact_name ?? ""
                let customerNumber = obj.primary_contact_number ?? ""
                
                return customerName.capitalized.contains(searchTerm.capitalized)
                    || customerNumber.capitalized.contains(searchTerm.capitalized)
            }
        }
        tableView.reloadData()
    }

    
    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableViewDatasource.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let contact = tableViewDatasource[indexPath.row]
        
        cell.textLabel?.text = languageBundle!.localizedString(forKey: "Customer Name:", value: "", table: nil) + " " + (contact.contact_name ?? "")
        cell.detailTextLabel?.text = languageBundle!.localizedString(forKey: "Customer Phone:", value: "", table: nil) + " " + (contact.primary_contact_number ?? "")
        
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedContact = tableViewDatasource[indexPath.row]
        performSegue(withIdentifier: "exit", sender: self)
    }
}

extension CustomerSearchTableViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTerm = searchText
        refreshSource()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        refreshSource()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchTerm = ""
        refreshSource()
        searchBar.showsCancelButton = false
        dismiss(animated: true, completion: nil)
    }
}
