$p_name='node-js-sample'

package{$p_name:
  ensure => latest
}

service {$p_name:
  ensure  => running,
  enable  => true
}

Package <| title== $p_name |> ~> Service<| title == $p_name |>
