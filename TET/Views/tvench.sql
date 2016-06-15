create view tvench as
select Cont_debitor as cont, Loc_de_munca, Suma as debit, 0 as credit, Tip_document, Numar_document, year(Data) as Anul, month(data) as Luna, day(data) as Ziua from pozincon
where cont_debitor between '6' and '7z'
union all
select Cont_creditor as cont, Loc_de_munca, 0 as debit, Suma as credit, Tip_document, Numar_document, year(Data) as Anul, month(data) as Luna, day(data) as Ziua from pozincon
where cont_creditor between '6' and '7zz'
