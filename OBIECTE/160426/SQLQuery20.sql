select * from webConfigTipuri t where t.ProcScriere like '%antetdoc%'
select * from ChangeLog c 
where c.ObjectName like 'wOPModificareAntetDoc%'
order by c.EventDate desc