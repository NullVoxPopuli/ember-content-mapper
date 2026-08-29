import { concat, uniqueId } from '@ember/helper';

import Component from '@glimmer/component';

export default class Foo extends Component {
	<template>
		{{#let (concat "team-permissions-" (uniqueId)) as |groupId|}}
			<div aria-labelledby={{groupId}} ...attributes>
				<div>
					<div id={{groupId}}>
					</div>
					{{#unless @isReadOnly}}
					{{/unless}}
				</div>
				<div>
					<div>
						{{#each @items as |allowedTeam|}}
							<div>
								<div>
									<div data-x={{allowedTeam.id}}>
									</div>
									{{#unless @isReadOnly}}
									{{/unless}}
								</div>
							</div>
							{{#if @isReadOnly}}
							{{/if}}
						{{/each}}
					</div>
				</div>
			</div>
		{{/let}}
	</template>
}
