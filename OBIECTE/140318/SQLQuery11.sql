select * --update f set vizibil=1
from WebConfigForm f --join test..webconfigform t on t.Meniu=f.Meniu and t.Tip=f.Tip and t.Subtip=f.Subtip and t.DataField=f.DataField
where t.Vizibil=1 and f.Vizibil=0