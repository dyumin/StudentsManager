//
//  RxTableViewSectionedAnimatedDataSource+DidMoveRowAtSourceIndexPathToDestinationIndexPath.swift
//  StudentsManager-IOS
//  Technically it's not a class extension, but who cares
//
//  Created by Дюмин Алексей on 12/05/2019.
//  Copyright © 2019 TeamUUUU. All rights reserved.
//

import Foundation

import RxDataSources

class RxTableViewSectionedAnimatedDataSourceDynamicWrapper<S: AnimatableSectionModelType> : RxTableViewSectionedAnimatedDataSource<S>
{
    public typealias DidMoveRowAtSourceIndexPathToDestinationIndexPath = (TableViewSectionedDataSource<S>, IndexPath, IndexPath) -> Void
    
    open var didMoveRowAtSourceIndexPathToDestinationIndexPath: DidMoveRowAtSourceIndexPathToDestinationIndexPath
    
    open override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath)
    {
        super.tableView(tableView, moveRowAt: sourceIndexPath, to: destinationIndexPath)
        didMoveRowAtSourceIndexPathToDestinationIndexPath(self, sourceIndexPath, destinationIndexPath)
    }
    
    public init(
        configureCell: @escaping ConfigureCell,
        titleForHeaderInSection: @escaping  TitleForHeaderInSection = { _, _ in nil },
        titleForFooterInSection: @escaping TitleForFooterInSection = { _, _ in nil },
        canEditRowAtIndexPath: @escaping CanEditRowAtIndexPath = { _, _ in false },
        canMoveRowAtIndexPath: @escaping CanMoveRowAtIndexPath = { _, _ in false },
        sectionIndexTitles: @escaping SectionIndexTitles = { _ in nil },
        sectionForSectionIndexTitle: @escaping SectionForSectionIndexTitle = { _, _, index in index },
        didMoveRowAtSourceIndexPathToDestinationIndexPath: @escaping DidMoveRowAtSourceIndexPathToDestinationIndexPath = { _, _, _ in }
        ) {
        self.didMoveRowAtSourceIndexPathToDestinationIndexPath = didMoveRowAtSourceIndexPathToDestinationIndexPath
        super.init(
            configureCell: configureCell,
            titleForHeaderInSection: titleForHeaderInSection,
            titleForFooterInSection: titleForFooterInSection,
            canEditRowAtIndexPath: canEditRowAtIndexPath,
            canMoveRowAtIndexPath: canMoveRowAtIndexPath,
            sectionIndexTitles: sectionIndexTitles,
            sectionForSectionIndexTitle: sectionForSectionIndexTitle
        )
    }
}
