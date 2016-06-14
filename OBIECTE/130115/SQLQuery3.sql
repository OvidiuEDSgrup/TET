select p.Pret*(1-p.Discount/100)
,* from pozcon p where p.Contract='9830623'