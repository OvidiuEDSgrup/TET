select * from pozcon p where not exists 
(select 1 from infotert i where i.Subunitate=p.Subunitate and i.Tert=p.Tert and i. )