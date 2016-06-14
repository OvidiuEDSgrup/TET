select * from ChangeLog c where c.ObjectName in 
('validsoldtert','docfac')
order by c.EventDate desc